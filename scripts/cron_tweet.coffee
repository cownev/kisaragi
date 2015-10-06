cronJob = require('cron').CronJob
twit    = require('twit')

module.exports = (robot) ->

  config =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET
  

  @client = new twit config
  @date   = new Date

  post_tweet = ->
    hour = @date.getHours()
    @client.post('statuses/update', {status: "#{hour}:00です"}, (err, data, response) ->
      # console.log response
      console.log "test tweet with cron at #{hour}:00"
    )

  job = new cronJob
    cronTime: "0 0 * * * *"
    start: false
    timeZone: "Asia/Tokyo"
    onTick: ->
      post_tweet()
  job.start()
