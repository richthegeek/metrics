module.exports = (app) ->

	metric2influx = require './influx_generator'

	app.put '/metrics/:id', (req, res, next) ->

		metric =
			_id:
				a: req.account
				i: req.params.id
			groups: req.body.groups
			fields: req.body.fields

		try
			throw {field: 'groups'} if Object.keys(metric.groups).length is 0
			throw {field: 'fields'} if Object.keys(metric.fields).length is 0
		catch e
			return next new Error 'A metric must have one or more ' + (e.field or 'groups/fields')

		for name, group of metric.groups
			if not group.period?
				return next new Error 'Metric groups must have a period'

			if not group.period.toString().match /^[0-9]+[smhdw]$/
				return next new Error 'Metric group periods must conform to /^[0-9]+[smhdw]$/'

			if isNaN group.retention = Number group.retention or '?'
				return next new Error 'Metric groups must have a numerical retention count'

			if group.retention > 5000
				return next new Error 'Metric groups cannot retain more than 5000 rollups'

			if not Array.isArray group.fields or false
				return next new Error 'Metric groups must have an array of fields'

			for field in group.fields
				if not metric.fields[field]?
					return next new Error 'Metric group fields must be defined in the metric fields list'

			# if group.fields.length is 0
			# 	return next new Error 'Metric groups must have at least one field'

		allowed_functions = ['count', 'min', 'max', 'mean', 'mode', 'median', 'distinct', 'percentile', 'histogram', 'derivative', 'sum', 'stddev', 'first', 'last']
		for name, obj of metric.fields
			regex = /^[a-z0-9_]+$/
			if not name.match regex
				return next new Error 'Metric field names must conform to ' + regex.toString()

			if not obj?.function?
				return next new Error 'Metric fields must have a function property'

			if obj.function not in allowed_functions
				return next new Error 'Metric field function must be one of ' + allowed_functions.join(', ')

			if not obj?.field?
				return next new Error 'Metric fields must have a field property'

			if 'string' isnt typeof obj.field
				return next new Error 'Metric fields "field" property must be a string'

		metric2influx metric, req.influx, (err) ->
			req.db.metrics.save metric, req.errorHandler (err, ok, result) ->
				res.send {
					status: "OK",
					message: "The metric has been " + (result.updatedExisting and "updated" or "inserted")
				}
		