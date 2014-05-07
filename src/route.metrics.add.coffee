module.exports = (app) ->
	# Add multiple datums to multiple metrics all in the same request
	app.post '/metrics', (req, res, next) ->
		write = {}
		count = 0
		for id, points of req.body
			target = req.account + '.' + id
			write[target] = [].concat points
			count += write[target].length

		req.influx.writeSeries write, req.errorHandler ->
			res.send {
				status: "OK",
				message: "#{count} datums received"
			}

	# Add one or more datums to a single metric
	app.post '/metrics/:id', (req, res, next) ->
		target = req.account + '.' + req.params.id
		input = [].concat req.body
		req.influx.writePoints target, input, req.errorHandler ->
			res.send {
				status: "OK",
				message: "#{input.length} datums received"
			}