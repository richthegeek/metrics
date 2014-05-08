module.exports = (metric, req, callback) ->
	async = require 'async'
	influx = req.influx

	###
		Turns the JSON schema into Influx "continuous queries",
		and ensures that those queries are the only ones for
		these series.
	###

	### input is something like:
		{
			"_id": {
				"a": "richthegeek",
				"i": "orders",
			},
			"groups": {
				"minute": {
					"period": 60,
					"retention": 1440,
					"fields": ["daily_revenue"]
				},
				"daily": {
					"period": 86400,
					"retention": 365,
					"fields": ["daily_revenue"]
				}
			},

			"fields": {
				"daily_revenue": {"function": "sum", "field": "some_random_field"}
			}
		}
	###
	### result should be like:
		
		SELECT sum(some_random_field) as daily_revenue FROM richthegeek.orders GROUP BY time(1m) INTO richthegeek.orders.minute
		SELECT sum(some_random_field) as daily_revenue FROM richthegeek.orders GROUP BY time(1d) INTO richthegeek.orders.daily

	###


	# map "name={field, function}" into "function(field) as name" strings
	fields = {}
	first_field = null
	for name, field of metric.fields
		first_field or= field.field

		# todo: document these two options somewhere!
		args = ''
		if field.function is 'percentile'
			field.percentile or= 50
			args = ', ' + field.percentile

		if field.function is 'histogram' and field.bucket_size
			args = ', ' + field.bucket_size

		fields[name] = "#{field.function}(#{field.field}#{args}) as #{name}"

	# series is the "collection name" in mongo-speak
	series = req.account + '.' + req.params.id
	queries = []
	for name, group of metric.groups

		# always count the number of entires in each grouping
		select = ["count(#{first_field}) as cardinality"]
		for field in group.fields
			select.push fields[field]

		grouping = ["time(#{group.period})"]
		# the "group" option is an optional list of fields to ALSO group by
		for field in group.group or []
			select.unshift field
			# because we are grouping by this, it's worth selecting these fields at the same time
			grouping.push field

		# aaand build the query
		query = ["SELECT"]
		query.push select.join ', '
		query.push 'FROM', series
		query.push 'GROUP BY', grouping.join ', '
		query.push 'INTO', series + '.' + name
		# send it onto the final query list
		queries.push query.join ' '

	# remove old continuous queries on this series
	# insert only continuous queries which aren't already present
	influx.getContinuousQueries (err, existing) ->
		remove = []
		create = queries.concat []
		for {id, query} in existing
			if (eseries = query.match /FROM ([a-z0-9_.-]+)/i).length >= 1
				if series is eseries[1]
					if query not in queries
						remove.push id
					else
						create = create.filter (v) -> v isnt query

		async.map remove, influx.dropContinuousQuery.bind(influx), (err1) ->
			async.map create, influx.query.bind(influx), (err2) ->
				callback err1 or err2, {
					queries: queries,
					removed: remove,
					created: create
				}
