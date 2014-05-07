module.exports = ->

	return (req, res, next) ->
		req.UA = require 'userapp'
		req.UA.initialize {appId: "536a50e608ae0"}

		next()