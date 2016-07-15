cronJob = require('cron').CronJob
twit    = require('twit')
moment  = require('moment')
mongodb = require('mongodb')

module.exports = (robot) ->
  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET

  twit_client = new twit keys
  mongo       = mongodb.MongoClient
  mongo_url   = process.env.MONGODB_URL

  tweet = ->
    hour = new Date().getHours()

    mongo.connect(mongo_url, (err, db) ->
      if err?
        robot.logger.error "#{err}"
      else
        collection = db.collection 'events'

        collection.findOne({"tweet_hour": hour}, (err, event) ->
          db.close()

          if err?
            robot.logger.error "#{err}"

          else if event?
            name     = event.name
            today    = moment().startOf 'day'
            eventday = moment event.date
            days     = eventday.diff today, 'days'
            hashtag  = "#イベント #カウントダウン"

            if days < 0
              robot.logger.info "already passed date of #{name}"
              return true

            else if days is 0
              message = "本日は#{name}。\n##{name} #{hashtag}"

            else
              message = "#{name}まであと#{days}日。\n##{name} #{hashtag}"

            twit_client.post 'statuses/update', {status: message}, (err, data, response) ->
              if err?
                robot.logger.error "#{err}"
              else
                robot.logger.info "tweet with cron at #{hour}:00"

          else
            robot.logger.info "not found any events at #{hour}:00"
        )
    )

  tweet_job = ->
    tweet()

  job = new cronJob
    cronTime: "0 0 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      tweet_job()
