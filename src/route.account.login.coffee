module.exports = (app) ->
	# Exchange login credentials for a token
	app.post '/account/login', (req, res, next) ->

		email = req.body.email or req.query.email
		password = req.body.password or req.query.password

		req.UA.User.login {login: email, password: password}, req.errorHandler (err, user) ->
			# todo: handle UserApp "locks"
			# cache the token for fast lookup
			req.cacheToken user.token, user.user_id, ->
				res.send {
					status: "OK",
					message: "The credentials were correct! The token will last for ",
					token: user.token
				}