module.exports = ->
	redis = require 'redis'
	client = redis.createClient()

	return (req, res, next) ->
		req.redis = client
		next()