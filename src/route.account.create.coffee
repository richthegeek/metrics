module.exports = (app) ->

	app.post '/account', (req, res, next) ->
		req.body ?= {}
		email = String req.body.email or ''
		password = String req.body.password or ''

		if not email.match /^[a-z0-9_\-+.]+\@[a-z0-9_\.]+$/i
			return next new Error 'You must provide a valid email address!'

		if not password.length > 5
			return next new Error 'Passwords must be at least 5 characters long'

		user =
			login: email,
			email: email,
			password: password

		req.UA.User.save user, req.errorHandler ->
			return res.send {
				status: "OK",
				message: "An account with that email address has been created, and will be available for use after email verification.",
				user: user
			}
