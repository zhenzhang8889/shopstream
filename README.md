# Shopstream

### Requirements

* MongoDB
* Redis
* Ruby 1.9
* Bundler

### App configuration

* `APP_HOST`, host of API app.
* `COLLECTOR_HOST`, host of collector node.js app.
* `SHOPIFY_API_KEY` & `SHOPIFY_API_SECRET` credentials for Shopify app.
* `PUSHER_KEY`.
* `MONGOLAB_URI` on Heroku.
* `REDISTOGO_URL` on Heroku.
* `GA_ACCOUNT`, the ID of Google Analytics account (optional).

### Production deployment

Required heroku addons:

* Mongolab
* RedisToGo
* Sendgrid
* Scheduler

Schduled tasks:

Task: `rake send_daily_notifications`, frequency: hourly, run on xx:50.
