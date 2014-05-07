module.exports = (app) ->

	files = [
		'account.create',
		'account.login',
		'account.get',

		'metrics.list'
		'metrics.save'
		'metrics.delete'
		'metrics.add',
		'metrics.get'
		'metrics.get_group'
	]

	for file in files
		require('./route.' + file)(app)