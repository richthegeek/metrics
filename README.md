metrics
=======

This is a server which provides a wrapper around InfluxDB, to provide time-series summaries over multiple accounts.

### Requirements:
 - [InfluxDB](http://influxdb.org/) for storing the time-series data
 - [MongoDB](http://mongodb.org) for storing the metric configurations, although this may be moved into Redis
 - [Redis](http://redis.io) for storing a cache of UserApp tokens
 - A [UserApp.io](http://userapp.io) account for authentication
 
Full documentation of the API is available on [Apiary](http://docs.influxmetrics.apiary.io/)
