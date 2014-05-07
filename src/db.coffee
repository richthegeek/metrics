module.exports = ->
	# attach a singleton instance of mongo to the request
	mongo = require 'mongodb'
	Q = require 'q'
	
	# use a promise to only create one connection!
	promise = null
	return (req, res, next) ->
		if not promise
			defer = Q.defer()
			promise = defer.promise

			mongo.MongoClient.connect 'mongodb://127.0.0.1:27017/metrics', (err, db) ->
				if err
					defer.reject err
				else
					defer.resolve db

		promise.then (db) ->
			req.db = db
			do next

		promise.catch (reason) ->
			next reason