module.exports = (app) ->
	async = require 'async'
	metric2influx = require './influx_generator'

	# save the configuration for a metric.
	app.put '/metrics/:id', (req, res, next) ->

		async.series {
			# get the user to ensure quota observance
			user: (next) -> req.UA.User.get {user_id: 'self'}, next
			old_metric: (next) -> req.getMetric req.account, req.params.id, next
		}, (err, {user, old_metric}) ->
			user = user[0].properties

			# copy from body to ensure we dont pick up any fluff
			metric =
				id: req.params.id
				groups: req.body.groups
				fields: req.body.fields

			# ensure we have at least one groups and fields entry
			try
				throw {field: 'groups'} if Object.keys(metric.groups).length is 0
				throw {field: 'fields'} if Object.keys(metric.fields).length is 0
			catch e
				return next new Error 'A metric must have one or more ' + (e.field or 'groups/fields')

			total_retention = user.quota_usage.value
			for name, group of metric.groups
				if not group.period?
					return next new Error 'Metric groups must have a period'

				if not group.period.toString().match /^[0-9]+[smhdw]$/
					return next new Error 'Metric group periods must conform to /^[0-9]+[smhdw]$/'

				if isNaN group.retention = Number group.retention or '?'
					return next new Error 'Metric groups must have a numerical retention count'

				total_retention += group.retention

				if not Array.isArray group.fields or false
					return next new Error 'Metric groups must have an array of fields'

				for field in group.fields
					if not metric.fields[field]?
						return next new Error 'Metric group fields must be defined in the metric fields list'

			old_retention = 0
			for name, group of old_metric
				old_retention += group.retention

			available_quota = user.quota.value - user.quota_usage.value + old_retention
			if total_retention > user.quota.value
				return next new Error "Total retention across all metrics (#{total_retention}) would be greater than allowed quota (#{user.quota.value}). Available quota is #{available_quota} datums retained."

			# todo: put this list somewhere more accessible
			allowed_functions = ['count', 'min', 'max', 'mean', 'mode', 'median', 'distinct', 'percentile', 'histogram', 'derivative', 'sum', 'stddev', 'first', 'last']
			for name, obj of metric.fields
				regex = /^[a-z0-9_]+$/
				if not name.match regex
					return next new Error 'Metric field names must conform to ' + regex.toString()

				if not obj?.function?
					return next new Error 'Metric fields must have a function property'

				if obj.function not in allowed_functions
					return next new Error 'Metric field function must be one of ' + allowed_functions.join(', ')

				if not obj?.field?
					return next new Error 'Metric fields must have a field property'

				if 'string' isnt typeof obj.field
					return next new Error 'Metric fields "field" property must be a string'

			metric2influx metric, req, (err) ->
				save = ->
					req.UA.User.save {user_id: 'self', properties: quota_usage: total_retention - old_retention}, req.errorHandler (err, user)->
						user = user.properties
						req.saveMetric req.account, metric, req.errorHandler (err, inserted) ->
							res.send {
								status: "OK",
								message: "The metric has been " + (inserted and "inserted" or "updated")
								metric: metric
								quota:
									used: total_retention
									remaining: user.quota.value - user.quota_usage.value
							}

				if metric.key?
					save()

				else
					req.generateKey req.account, metric.id, req.errorHandler (err, key) ->
						metric.key = key
						save()