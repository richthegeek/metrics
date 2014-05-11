express = require 'express'

app = express()
# bundled middleware
app.use require('morgan')('short')
app.use '/api', require('body-parser').json()
# error handling
require('./error_handler')(app)

# attach resources, only needed for the API really
app.use '/api', do require './redis'
app.use '/api', do require './userapp'
app.use '/api', do require './influx'
# authorisation on all API routes
app.use '/api', do require './authorise'

require('./routes')(app)

app.listen 6872 # MeTRiC