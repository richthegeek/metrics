module.exports = ->

	return (req, res, next) ->
		req.UA = require 'userapp'
		# todo: move this appId somewhere else
		req.UA.initialize {appId: "536a50e608ae0"}

		next()