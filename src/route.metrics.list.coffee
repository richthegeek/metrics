module.exports = (app) ->

	app.get '/metrics', (req, res, next) ->
		req.db.metrics.find({"_id.a": req.account}).toArray req.errorHandler (err, metrics) ->
			res.send metrics.map (metric) ->
				metric._id = metric._id.i
				return metric