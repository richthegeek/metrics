module.exports = (api) ->

	api.get '/metrics/:id', (req, res, next) ->
		series = [req.account, req.params.id].join '.'
		
		format = req.query.format ? 'json'

		req.influx.query 'SELECT * FROM /' + series + '\..*/', req.errorHandler (err, data) ->
			for datum in data
				datum.group = datum.name.replace series + '.', ''

				# remove sequence_number
				datum.columns = ['time'].concat datum.columns.slice(2)
				datum.points = datum.points.map (row) ->
					row[1] = 
					[row[0]].concat row.slice(2)


			if format is 'csv'
				output = 'TODO'
				# output = [data.columns]
				# 	.concat(data.points)
				# 	.map((row) -> row.map(JSON.stringify).join(','))
				# 	.join("\n")

			else
				output = {}
				for datum in data
					output[datum.group] = datum.points.map (row) ->
						obj = {}
						for i, val of row
							key = datum.columns[i]
							obj[key] = val
						return obj
				
			res.send output

