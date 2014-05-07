module.exports = (app) ->

	# attach a helper function which will catch callback errors
	# and mangle them into a proper error message for sending
	# onwards to the final error-handler. Saves a lot of boilerplate!
	app.use (req, res, next) ->
		req.errorHandler = (cb) ->
			return (args...) ->
				if err = args[0]
					console.log 'ERROR!'
					if not (err instanceof Error)
						err = new Error err.message or err
					return next err
				cb args...
		next()

	# normalise the output of errors
	app.use (err, req, res, next) ->
		status = err.status ? 500
		res.send status, {
			status: 'Error'
			message: err.message
		}
