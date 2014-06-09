$ ->
	# update the plan list
	UserApp.Plan.search {price_list_id: "VbfYIdDOQQOD-gkUyg7QhQ"}, (err, result) ->
		select = $ 'select[name=plan]'
		select.empty()
		select.removeAttr 'disabled'

		options = {}
		for plan in result.items.reverse()
			options[plan.plan_id] = $('<option>')
				.attr('name', plan.plan_id)
				.html(plan.name)
				.appendTo select
			
		UserApp.Plan.get {plan_id: Object.keys(options)}, (err, plans) ->
			for plan in plans when option = options[plan.plan_id]
				option.html plan.name + ': £' + plan.price + '/month for ' + plan.properties.quota.value + ' points'

	getValues = (context) ->
		obj = {}
		$('*[name]', context).each ->
			name = $(this).attr('name')
			val = $(this).val()
			obj[name] = val
		return obj

	# handle login...
	$('form#login').submit ->
		API.account_login getValues(@), (err, result)->
			if result?.token?
				document.cookie = "metrics_token=#{result.token}"
				return window.location = '/'

			alert err or 'Unknown error'
		return false

	# handle registration...
	$('form#register').submit ->
		API.account_create getValues(@), (err, result)->
			
			alert err or result.message or 'Unknown error'
		return false		