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

  client     = new twit keys
  keyword    = "#イベント"

  rl.on('line', (line) ->
    word = " " + "-" + line.trim()
    keyword += word
  )
  rl.on('close', ->
    robot.logger.info "follow script search keyword: '#{keyword}'"
  )

  follow = ->
    client.get 'search/tweets', { q: "#{keyword}", count: 10 }, (err, data, response) ->
      data.statuses.forEach (tweet) ->
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
