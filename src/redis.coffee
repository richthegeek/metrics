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
				if err
					return callback err
				
				if created is 'OK'
					return callback null, key

				# duplicate key, so rerun until we dont duplicate the key
				req.generateKey account, metric, callback

		req.getTokenInfo = (token, callback) ->
			client.get 'metrics:tokens:' + token, req.errorHandler callback
		
		req.cacheToken = (token, account, callback) ->
			client.set ['metrics:tokens:' + token, account, 'EX', 600], req.errorHandler callback

		req.saveMetric = (account, metric, callback) ->
			client.hset 'metrics:metrics:' + req.account, metric.id, JSON.stringify(metric), req.errorHandler callback

		req.getMetric = (account, id, callback) ->
			client.hget 'metrics:metrics:' + account, id, req.errorHandler (err, json) ->
				try
					callback err, JSON.parse json
				catch e
					return callback e

		req.getMetrics = (account, callback) ->
			client.hgetall 'metrics:metrics:' + account, req.errorHandler (err, object) ->
				for key, json of object or {}
					object[key] = JSON.parse json
					delete object[key].id
				callback err, object

		
		next()