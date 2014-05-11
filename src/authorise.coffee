module.exports = ->
	return (req, res, next) ->
		# error handling is different here as we are in a middleware
		# and because we want to send a 401 in all cases
		error = (message) -> req.errorHandler(->)(status: 401, message: message)

		# skip authorisation for registration and login
		route = req.method.toUpperCase() + ' ' + req.path
		unauthorised = [
			'POST /account',
			'POST /account/login'
		]
		if route in unauthorised
			return next()

		# tokens are UA-provided short-life keys
		token = req.query.token
		# keys are self-generated permanent against a single metric
		key = req.query.key

		if token?
			# configure UserApp to use this token for this request
			# TODO: ensure this actually works as expected with multiple users
			req.UA.setToken token
			return req.getTokenInfo token, (err, account) ->
				# token was cached, so we're authorised
				if account
					req.account = account
					return next()

				# if we cant get a cached version of the key then we
				# load the account from UserApp and cache the result in Redis
				req.UA.User.get {user_id: 'self'}, (err, user) ->
					if user?[0]?.user_id?
						uid = user[0].user_id
						return req.cacheToken token, uid, ->
							req.account = uid
							# store this to occasionally reduce a request on GET /account
							res.user = user[0]
							next()

							# heartbeat the token
							req.UA.Token.heartbeat -> null

					return error 'The provided token was invalid or has expired. Please login.'

		if route.match(/^POST \/metrics\/[^\/]+$/) and key?
			return req.getKeyInfo key, req.errorHandler (err, info) ->
				if not info
					return error 'Unrecognised key'

				if route isnt 'POST /metrics/' + info.metric
					return error 'Key is not valid for this metric'

				req.account = info.account
				next()


		return error 'This is an authorised route but no token or key was provided.'
