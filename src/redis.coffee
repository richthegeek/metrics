module.exports = ->
	redis = require 'redis'
	# todo: allow options on redis client init
	client = redis.createClient()

	return (req, res, next) ->
		req.redis = client
		next()