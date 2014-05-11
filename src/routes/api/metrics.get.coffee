module.exports = (api) ->

	# get all roll-ups from this metric
	api.get '/metrics/:id', (req, res, next) ->
		series = [req.account, req.params.id].join '.'
		
		# default the format to JSON
		format = req.query.format ? 'json'

		# todo: ensure this is performant!
		req.influx.query 'SELECT * FROM /' + series + '\..*/', req.errorHandler (err, data) ->
			for datum in data
				datum.group = datum.name.replace series + '.', ''

				# remove sequence_number
				datum.columns = ['time'].concat datum.columns.slice(2)
				datum.points = datum.points.map (row) ->
					row[1] = 
					[row[0]].concat row.slice(2)


			if format is 'csv'
				# todo: figure out how to nicely show CSV data for multiple types. might be impossible?
				output = 'todo'

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

