module.exports = ->
	# attach a singleton instance of mongo to the request
	mongo = require 'mongodb'
	Q = require 'q'
	
	# use a promise to only create one connection!
	defer = Q.defer()
	promise = defer.promise

	# todo: move this connection string somewhere else
	mongo.MongoClient.connect 'mongodb://127.0.0.1:27017/metrics', (err, db) ->
		if err
			defer.reject err
		else
			# connect this here, for ease of use.
			db.metrics = db.collection 'metrics'
			defer.resolve db

	return (req, res, next) ->
		promise.then (db) ->
			req.db = db
			do next

		promise.catch (reason) ->
			next reason