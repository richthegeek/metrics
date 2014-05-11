module.exports = (app) ->

	async = require 'async'

	# list all configured metrics associated with this account
	app.get '/metrics', (req, res, next) ->
		async.series {
			series: (next) -> req.influx.query "SELECT * FROM /#{req.account}\..*/ LIMIT 1", next
			configs: (next) -> req.getMetrics req.account, next
		}, (err, result) ->
			if err then next err

			res.send result.series.reduce (obj, series) ->
				if series.points.length is 0
					return obj

				name = series.name.split('.').slice(1)
				series.name = name[0]
				series.type = (if name.length is 1 then 'input' else 'output')
				
				row = {}
				for i, column of series.columns when column isnt 'sequence_number'
					row[column] = series.points[0][i]

				obj[series.name] or= {}
				if series.type is 'input'
					obj[series.name].sample = row
				else
					group_name = name[1]
					obj[series.name].groups[group_name] ?= {}
					obj[series.name].groups[group_name].sample = row

				return obj
			, result.configs
