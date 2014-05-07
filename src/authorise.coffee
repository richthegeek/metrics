# return true if the account is authorised
module.exports = ->
	return (req, res, next) ->
		console.log 'auth'

		route = req.method.toUpperCase() + ' ' + req.path
		unauthorised = [
			'POST /account',
			'POST /account/login'
		]
		if route in unauthorised
			return next()

		token = req.query.token

		if not token?
			return next new Error 'This is an authorised route but no token was provided.'

		key = 'metrics:tokens:' + token
		req.UA.setToken token
		
		req.redis.get key, req.errorHandler (err, account) ->
			if account
				req.account = account
				return next()

			req.UA.User.get {user_id: 'self'}, (err, user) ->
				if user?[0]?.user_id?
					uid = user[0].user_id
					return req.redis.set [key, uid, "EX", 600], (err) ->
						if err
							return next err

						req.account = uid
						res.user = user[0]
						next()

				return next new Error 'The provided token was invalid or has expired. Please login.'