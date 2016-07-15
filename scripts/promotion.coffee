cronJob = require('cron').CronJob
twit    = require('twit')
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
    mongo.connect(mongo_url, (err, db) ->
      if err?
        robot.logger.error "#{err}"
      else
        collection = db.collection 'clients'

        collection.findOne({}, (err, client) ->
          db.close()

          if err?
            robot.logger.error "#{err}"

          else if client?
            name      = client.name
            message   = client.messages[Math.floor Math.random() * client.messages.length]
            link      = client.links[Math.floor Math.random() * client.links.length]
            hashtag   = client.tags.join(' ')
            promotion = "#{message}\n#{link}\n#{hashtag}"

            twit_client.post 'statuses/update', {status: promotion}, (err, data, response) ->
              if err?
                robot.logger.error "#{err}"
              else
                robot.logger.info "promotion tweet for #{name}"
          else
            robot.logger.info "not found any clients"
        )
    )

  tweet_job = ->
    tweet()

  job = new cronJob
    cronTime: "0 30 12,21 * * 0,3,5"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      tweet_job()
