module.exports = ->
	redis = require 'redis'
	# todo: allow options on redis client init
	client = redis.createClient()


	return (req, res, next) ->
		req.redis = client
		
		req.getAccount = (token, callback) ->
			client.get 'metrics:tokens:' + token, req.errorHandler callback
		req.cacheToken = (token, account, callback) ->
			client.set ['metrics:tokens:' + token, account, 'EX', 600], req.errorHandler callback
		
		next()