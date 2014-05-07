express = require 'express'

app = express()
# bundled middleware
app.use require('morgan')('short')
app.use require('body-parser').json()
# error handling
require('./error_handler')(app)

# attach resources
app.use do require './redis'
app.use do require './userapp'
app.use do require './db'
app.use do require './influx'
# authorisation on all routes
app.use do require './authorise'

require('./routes')(app)

app.listen 6872 # MeTRiC