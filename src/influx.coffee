module.exports = ->
	influx = require 'influx'
	client = influx 'localhost', 8086, 'metrics', 'metrics', 'metrics'

	return (req, res, next) ->
		req.influx = client
		next()