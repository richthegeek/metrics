module.exports = (app) ->

	app.post '/metrics', (req, res, next) ->
		write = {}
		for id, points of req.body
			target = req.account + '.' + id
			write[target] = [].concat points

		req.influx.writeSeries write, req.errorHandler ->
			res.send {
				targets: Object.keys(write)
				result: arguments
			}

	app.post '/metrics/:id', (req, res, next) ->
		target = req.account + '.' + req.params.id
		input = [].concat req.body
		req.influx.writePoints target, input, req.errorHandler ->
			res.send {
				target: target,
				result: arguments
			}