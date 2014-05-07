express = require 'express'
influx = require 'influx'

app = express()
app.use require('morgan')('short')
app.use require('body-parser').json()

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

app.use do require './redis'
app.use do require './userapp'
app.use do require './db'
app.use do require './authorise'

require('./routes')(app)

app.use (err, req, res, next) ->
	res.send 500, {
		status: 'Error'
		message: err.message
	}

app.listen 6872 # M T R C