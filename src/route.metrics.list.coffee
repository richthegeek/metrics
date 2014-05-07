module.exports = (app) ->

	app.get '/metrics', (req, res, next) ->
		req.db.metrics.find({"_id.a": req.account}).toArray req.errorHandler (err, metrics) ->
			res.send metrics.reduce (out, metric) ->
				id = metric._id.i
				delete metric._id
				out[id] = metric
				return out
			, {}