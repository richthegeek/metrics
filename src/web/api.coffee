window.API = new class API

	constructor: ->
		@token = null
		@keys = {}

	setToken: (@token) -> @
	setKey: (group, key) -> @keys[group] = key

	account_create: (user, callback) ->
		@post {path: '/account', data: user}, callback

	account_login: (user, callback) ->
		@post {path: '/account/login', data: user}, (err, result) ->
			if result?.token?
				@setToken result.token

			callback err, result

	account_get: (callback) ->
		@get {path: '/account', token: true}, callback

	metrics_list: (callback) ->
		@get {path: '/metrics', token: true}, callback

	metrics_add_multi: (data, callback) ->
		@post {path: '/metrics', data: data, token: true}, callback

	metrics_add: (metric, points, callback) ->
		@post {path: "/metrics/#{metric}", data: points, token: true, key: metric}, callback

	metrics_configure: (metric, config, callback) ->
		@put {path: "/metrics/#{metric}", data: config, token: true}, callback

	metrics_delete: (metric, callback) ->
		@delete {path: "/metrics/#{metric}", token: true}, callback

	metrics_get: (metric, group, callback) ->
		@get {path: "/metrics/#{metric}/#{group}", token: true}, callback

	metrics_get_all: (metric, callback) ->
		@get {path: "/metrics/#{metric}", token: true}, callback

	request: (opts, callback) ->
		options = {}
		options.cache = false
		options.contentType = 'application/json'
		options.data = JSON.stringify opts.data
		options.dataType = 'json'
		options.type = opts.method
		options.url = '/api' + opts.path

		if (opts.key and opts.token) and (not @token and not @keys[opts.key])
				return callback 'Requests to ' + options.url + ' require either a token or a key'

		if opts.key
			if not @keys[opts.key]
				return callback 'Requests to ' + options.url + ' require a key but none provided'
			options.url += '?key=' + @keys[opts.key]
			
		if opts.token
			if not @token
				return callback 'Requests to ' + options.url + ' require a token. Call @setToken first!'
			options.url += '?token=' + @token

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
