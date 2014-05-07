module.exports = (app) ->

	app.get '/account', (req, res, next) ->
		
		loadUser = (next) -> req.UA.User.get {user_id: 'self'}, next
		if req.user
			loadUser = (next) -> next null, req.user
		
		loadUser req.errorHandler (err, user) ->
			user = user[0] or user

			if not user
				return next new Error 'Could not retrieve user.'

			return res.send {
				id: req.account
				email: user.email
			}