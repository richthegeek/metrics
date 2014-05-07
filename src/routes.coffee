module.exports = (app) ->

	files = [
		'account.create',
		'account.login',
		'account.get',
		# todo: account.update, specifically handling pricing plans using UserApp
		# todo: account.verify, for email verification flow

		'metrics.list'
		'metrics.save'
		'metrics.delete'
		'metrics.add',
		'metrics.get'
		'metrics.get_group'
	]

	for file in files
		require('./route.' + file)(app)