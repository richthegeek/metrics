module.exports = ->
	return (req, res, next) ->
		# skip authorisation for registration and login
		route = req.method.toUpperCase() + ' ' + req.path
		unauthorised = [
			'POST /account',
			'POST /account/login'
		]
		if route in unauthorised
			return next()

		token = req.query.token
		# all authorised routes must have a token
		if not token?
			return next new Error 'This is an authorised route but no token was provided.'

		# configure UserApp to use this token for this request
		# TODO: ensure this actually works as expected with multiple users
		req.UA.setToken token
		
		req.getAccount token, (err, account) ->
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

				return next new Error 'The provided token was invalid or has expired. Please login.'