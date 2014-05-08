module.exports = (app) ->

	# list all configured metrics associated with this account
	app.get '/metrics', (req, res, next) ->

		req.redis.hgetall 'metrics:metrics:' + req.account, req.errorHandler (err, result) ->
			for key, object of result
				result[key] = JSON.parse(object)

			res.send result