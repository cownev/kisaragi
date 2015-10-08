config  = require('../config/events.json')
cronJob = require('cron').CronJob
twit    = require('twit')

module.exports = (robot) ->

  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET
  
  @client = new twit keys

  calcDiffDays = (event_date) ->
    today    = new Date().getTime()
    eventday = Date.parse event_date
		  
    return Math.ceil (eventday - today) / (1000 * 60 * 60 *24)

  post_tweet = ->
    hour = new Date().getHours()

    name = config.events[0].name
    days = calcDiffDays config.events[0].date

    @client.post('statuses/update', {status: "#{name}まで あと#{days}日！！"}, (err, data, response) ->
      console.log "test tweet with cron at #{hour}:00"
    )
  
  job = new cronJob
    cronTime: "0 0 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      post_tweet()
