module.exports = (app) ->
	async = require 'async'

	# remove all data associated with a metric
	app.delete '/metrics/:id', (req, res, next) ->

		req.redis.hexists 'metrics:metrics:' + req.account, req.params.id, req.errorHandler (err, result) ->
			if not result
				return next new Error 'No such metric!'

			req.redis.hdel 'metrics:metrics:' + req.account, req.params.id, req.errorHandler (err, result) ->
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

					async.each collections, req.influx.dropSeries.bind(req.influx), ->
						async.each cqs, req.influx.dropContinuousQuery.bind(req.influx), req.errorHandler ->
							res.send {
								status: "OK"
								message: "The metric was deleted, including all data"
							}