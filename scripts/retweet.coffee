cronJob = require('cron').CronJob
twit    = require('twit')
mongodb = require('mongodb')
fs      = require('fs')
rl      = require('readline')

module.exports = (robot) ->
  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET

  client          = new twit keys
  mongo           = mongodb.MongoClient
  mongo_url       = process.env.MONGODB_URL
  ng_uids         = []
  no_retweet_uids = []
  counter         = 0

  uids_rl  = rl.createInterface({
    'input': fs.ReadStream('./config/ng_uids.txt'), 'output': {}
  })

  uids_rl.on('line', (line) ->
    ng_uids.push(line)
  )
  uids_rl.on('close', ->
    no_retweet_uids = ng_uids.concat()
    client.get "account/verify_credentials", (err, data, response) ->
      if err?
        robot.logger.error "#{err}"
      else
        no_retweet_uids.push(data.id_str)
        robot.logger.info "succeeded to add #{data.screen_name}'s uid to no_retweet_uids"

      robot.logger.info "ng_uids: '#{ng_uids}'"
  )

  create_search_keywords = (callback) ->
    mongo.connect(mongo_url, (err, db) ->
      if err?
        robot.logger.error "#{err}"
      else
        collection = db.collection 'ngs'
        keywords   = "#イベント"

        collection.find({"keyword": {$exists:true}}).each( (err, doc) ->
          if err?
            robot.logger.error "#{err}"
          else if doc?
            keyword = " " + "-\"" + doc.keyword + "\""
            keywords += keyword
          else
            callback(keywords)
        )
    )

  retweet = (keywords) ->
    robot.logger.info "retweet search keywords: '#{keywords}'"

    client.get 'search/tweets', { q: "#{keywords}", count: 10, result_type: "mixed"}, (err, data, response) ->
      data.statuses.some (tweet) ->
        if counter >= 72
          no_retweet_uids.length = 0
          no_retweet_uids = ng_uids.concat()

        unless tweet.user.id_str in no_retweet_uids
          client.post 'statuses/retweet/:id', { id: tweet.id_str }, (err, data, response) ->
            if err?
              robot.logger.error "#{err} #{tweet.user.screen_name}'s #{tweet.id_str}"
            else
              robot.logger.info "retweet #{tweet.user.screen_name}'s #{tweet.id_str}"
              no_retweet_uids.push(tweet.user.id_str)
              counter++

            robot.logger.info "retweeted_uids counter: #{counter}"

          return true

  retweet_job = ->
    create_search_keywords(retweet)

  job = new cronJob
    cronTime: "0 10,30,50 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      retweet_job()
