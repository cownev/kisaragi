config  = require('../config/events.json')
cronJob = require('cron').CronJob
twit    = require('twit')
moment  = require('moment')

module.exports = (robot) ->
  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET
  
  client = new twit keys

  post_tweet = ->
    hour = new Date().getHours()

    event = config.events.filter( (event, index) ->
      if event.tweet_hour is hour then true else false
    ).shift()

    if event?
      name     = event.name
      today    = moment().startOf 'day'
      eventday = moment event.date
      days     = eventday.diff today, 'days'

      client.post 'statuses/update', {status: "#{name}まで あと#{days}日。\ntesting: #{hour}:00"}, (err, data, response) ->
        if err?
          robot.logger.error "#{err}"
        else
          robot.logger.info "tweet with cron at #{hour}:00"
  
  job = new cronJob
    cronTime: "0 0 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      post_tweet()
