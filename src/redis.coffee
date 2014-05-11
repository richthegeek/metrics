module.exports = ->
	crypto = require 'crypto'
	redis = require 'redis'
	# todo: allow options on redis client init
	client = redis.createClient()

	return (req, res, next) ->
		req.redis = client
		
		req.getKeyInfo = (key, callback) ->
			client.get 'metrics:keys:' + key, req.errorHandler (err, info) ->
				if not info
					return callback()
				else
					[account,metric] = info.split('|')
					callback null, {account: account, metric: metric}

		req.generateKey = (account, metric, callback) ->
			key = crypto.createHash('sha1').update(Math.random().toString()).digest('hex')
			value = [account, metric].join('|')
			client.set ['metrics:keys:' + key, value, 'NX'], (err, created) ->
				console.log arguments
				if err
					return callback err
				
				if created
					return callback null, key

				# duplicate key, so rerun until we dont duplicate the key
				req.generateKey account, metric, callback

		req.getTokenInfo = (token, callback) ->
			client.get 'metrics:tokens:' + token, req.errorHandler callback
		
		req.cacheToken = (token, account, callback) ->
			client.set ['metrics:tokens:' + token, account, 'EX', 600], req.errorHandler callback
		
		next()