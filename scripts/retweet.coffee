cronJob = require('cron').CronJob
twit    = require('twit')
fs      = require('fs')
rl      = require('readline')

module.exports = (robot) ->
  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET

  client          = new twit keys
  keyword         = "#イベント"
  ng_uids         = []
  no_retweet_uids = []
  counter         = 0

  keywords_rl  = rl.createInterface({
    'input': fs.ReadStream('./config/ng_keywords.txt'), 'output': {}
  })
  uids_rl  = rl.createInterface({
    'input': fs.ReadStream('./config/ng_uids.txt'), 'output': {}
  })

  keywords_rl.on('line', (line) ->
    word = " " + "-\"" + line.trim() + "\""
    keyword += word
  )
  keywords_rl.on('close', ->
    robot.logger.info "retweet script search keyword: '#{keyword}'"
  )

  uids_rl.on('line', (line) ->
    ng_uids.push(line)
  )
  uids_rl.on('close', ->
    no_retweet_uids = ng_uids.concat()
    robot.logger.info "ng_uids: '#{ng_uids}'"
  )

  retweet = ->
    client.get 'search/tweets', { q: "#{keyword}", count: 10, result_type: "mixed"}, (err, data, response) ->
      data.statuses.some (tweet) ->
        if counter >= 72
          no_retweet_uids.length = 0
          no_retweet_uids = ng_uids.concat()

        unless tweet.user.id in no_retweet_uids
          client.post 'statuses/retweet/:id', { id: tweet.id_str }, (err, data, response) ->
          if err?
            robot.logger.error "#{err}"
          else
            robot.logger.info "retweet #{tweet.user.screen_name}'s #{tweet.id_str}"

          no_retweet_uids.push(tweet.user.id)
          counter++
          return true

      robot.logger.info "no_retweet_uids: #{no_retweet_uids}"


  job = new cronJob
    cronTime: "0 10,30,50 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      retweet()
