config  = require('../config/events.json')
cronJob = require('cron').CronJob
twit    = require('twit')
moment  = require("moment")

module.exports = (robot) ->
  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET
  
  @client = new twit keys

  post_tweet = ->
    hour = new Date().getHours()

    if hour in [0, 3, 6, 9, 12, 15, 18, 21]
    #if config.events[hour]?
      id       = hour / 3
      name     = config.events[id].name
      today    = moment().startOf 'day'
      eventday = moment config.events[id].date
      days     = eventday.diff today, 'days'

      @client.post('statuses/update', {status: "#{name}まで あと#{days}日。testing: #{hour}:00"}, (err, data, response) ->
        console.log "test tweet with cron at #{hour}:00"
      )
  
  job = new cronJob
    cronTime: "0 0 0-23/3 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      post_tweet()
