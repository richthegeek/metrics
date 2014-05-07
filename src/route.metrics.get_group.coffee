module.exports = (api) ->

	api.get '/metrics/:id/:group', (req, res, next) ->
		series = [req.account, req.params.id, req.params.group].join '.'
		
		format = req.query.format ? 'json'

		req.influx.query 'SELECT * FROM ' + series, req.errorHandler (err, data) ->
			data = data[0] or data

			# remove sequence_number
			data.columns = ['time'].concat data.columns.slice(2)
			data.points = data.points.map (row) ->
				[row[0]].concat row.slice(2)

			if format is 'csv'
				output = [data.columns]
					.concat(data.points)
					.map((row) -> row.map(JSON.stringify).join(','))
					.join("\n")

			else
				output = data.points.map (row) ->
					obj = {}
					for i, val of row
						key = data.columns[i]
						obj[key] = val
					return obj

				
			res.send output

