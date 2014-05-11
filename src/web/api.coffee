window.API = new class API

	constructor: ->
		null

	account_create: (user, callback) ->
		@post {path: '/account', data: user}, callback

	account_login: (user, callback) ->
		@post {path: '/account/login', data: user}, callback

	request: (opts, callback) ->
		options = {}
		options.cache = false
		options.contentType = 'application/json'
		options.data = JSON.stringify opts.data
		options.dataType = 'json'
		options.type = opts.method
		options.url = '/api' + opts.path

		$.ajax(options).always (resp, status, message) ->
			result = resp.responseJSON or resp
			
			if status is 'error' or result.status is 'Error'
				return callback result.message or message, {}

			return callback null, result

	get: (options, callback) ->
		options.method = 'get'
		@request options, callback

	post: (options, callback) ->
		options.method = 'post'
		@request options, callback

	put: (options, callback) ->
		options.method = 'put'
		@request options, callback

	delete: (options, callback) ->
		options.method = 'delete'
		@request options, callback
