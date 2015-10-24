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

  client        = new twit keys
  keyword       = "#イベント"
  no_folow_uids = []
  counter       = 0

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
    no_folow_uids.push(line)
  )
  uids_rl.on('close', ->
    client.get "account/verify_credentials", (err, data, response) ->
      if err?
        robot.logger.error "#{err}"
      else
        no_folow_uids.push(data.id_str)
        robot.logger.info "succeeded to add #{data.screen_name}'s uid to no_follow_uids"

      robot.logger.info "no_folow_uids: '#{no_folow_uids}'"
  )

  follow = ->
    client.get 'search/tweets', { q: "#{keyword}", count: 10 }, (err, data, response) ->
      data.statuses.forEach (tweet) ->
        unless tweet.user.id_str in no_folow_uids
          client.post 'friendships/create', {user_id: tweet.user.id}, (err, data, response) ->
            if err?
              robot.logger.error "#{err}"
            else
              robot.logger.info "followed #{tweet.user.screen_name}"

  job = new cronJob
    cronTime: "0 15,45 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      follow()
