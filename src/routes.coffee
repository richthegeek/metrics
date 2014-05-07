module.exports = (app) ->

	for file in ['account.create', 'account.login', 'account.get']
		require('./route.' + file)(app)