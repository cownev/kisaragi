cronJob = require('cron').CronJob
twit    = require('twit')
rs      = require('fs').ReadStream('./config/ng_keyword_list.txt')
rl      = require('readline').createInterface({'input': rs, 'output': {}})

module.exports = (robot) ->
  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET

  client       = new twit keys
  keyword      = "#イベント"
  retweet_uids = []

  rl.on('line', (line) ->
    word = " " + "-\"" + line.trim() + "\""
    keyword += word
  )
  rl.on('close', ->
    robot.logger.info "retweet script search keyword: '#{keyword}'"
  )

  retweet = ->
    client.get 'search/tweets', { q: "#{keyword}", count: 10 }, (err, data, response) ->
      data.statuses.some (tweet) ->
        if retweet_uids.length is 72
          retweet_uids.length = 0

        if retweet_uids.indexOf(tweet.user.id) < 0
          client.post 'statuses/retweet/:id', { id: tweet.id_str }, (err, data, response) ->
          if err?
            robot.logger.error "#{err}"
          else
            robot.logger.info "retweet #{tweet.user.screen_name}'s #{tweet.id_str}"

          retweet_uids.push(tweet.user.id)
          return true

      robot.logger.info "[test] retweet_uids: #{retweet_uids}"

  job = new cronJob
    cronTime: "0 10,30,50 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      retweet()
