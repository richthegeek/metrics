module.exports = (app) ->

	# Web resources
	express = require 'express'
	cookieParser = require 'cookie-parser'

	# redirect homepage to login if not authorised
	app.get '/', cookieParser(), (req, res, next) ->
		if not req.cookies.metrics_token?
			return res.redirect 302, '/login'
		next()
	
	# add .html for static serving
	app.use (req, res, next) ->
		if not req.path.match(/^\/(api|public)/)
			req.url = req.url.replace(/(\.[a-z]+)?$/, '.html')
		return next()

	# mount static resources
	console.log __dirname + '../web'
	app.use '/public/css', express.static(__dirname + '/../../web/css')
	app.use '/public/js', express.static(__dirname + '/../web')
	app.use '/public/images', express.static(__dirname + '/../../web/images')
	app.use '/', express.static(__dirname + '/../../web/html')

	# API routes
	files = [
		'account.create',
		'account.login',
		'account.get',
		# todo: account.update, specifically handling pricing plans using UserApp
		# todo: account.verify, for email verification flow

		'metrics.list'
		'metrics.save'
		'metrics.delete'
		'metrics.add',
		'metrics.get'
		'metrics.get_group'
	]

	api_router = express.Router()
	for file in files
		require('./api/' + file)(api_router)
	app.use '/api', api_router
