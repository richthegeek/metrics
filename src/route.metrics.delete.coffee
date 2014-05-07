module.exports = (app) ->
	async = require 'async'

	# remove all data associated with a metric
	app.del '/metrics/:id', (req, res, next) ->

		id =
			a: req.account
			i: req.params.id

		req.db.metrics.findOne {_id: id}, req.errorHandler (err, metric) ->
			if not metric
				return next new Error 'No such metric!'

			# find the names of any continuous queries
			req.influx.getContinuousQueries (err, existing) ->
				cqs = []
				# also generate a list of collections to drop
				collections = ["#{req.account}.#{req.params.id}"]
				for {id, query} in existing
					# match FROM x INTO y
					if (series = query.match /FROM ([a-z0-9_.-]+).+?INTO ([a-z0-9_.-]+)/i).length >= 1
						if series[1].indexOf(collections[0]) is 0
							cqs.push id
							collections.push series[2]

				async.forEach collections, req.influx.dropSeries.bind(req.influx), ->
					async.forEach cqs, req.influx.dropContinuousQuery.bind(req.influx), req.errorHandler ->
						res.send {
							status: "OK"
							message: "The metric was deleted, including all data"
						}