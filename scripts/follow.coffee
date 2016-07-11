cronJob       = require('cron').CronJob
twit          = require('twit')
fs            = require('fs')
rl            = require('readline')
search_action = require('../lib/search_action')

module.exports = (robot) ->
  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET

  client        = new twit keys
  no_folow_uids = []
  counter       = 0

  uids_rl  = rl.createInterface({
    'input': fs.ReadStream('./config/ng_uids.txt'), 'output': {}
  })

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

  follow = (keywords) ->
    robot.logger.info "follow search keywords: '#{keywords}'"

    client.get 'search/tweets', { q: "#{keywords}", count: 10 }, (err, data, response) ->
      data.statuses.forEach (tweet) ->
        unless tweet.user.id_str in no_folow_uids
          client.post 'friendships/create', {user_id: tweet.user.id}, (err, data, response) ->
            if err?
              robot.logger.error "#{err}"
            else
              robot.logger.info "followed #{tweet.user.screen_name}"

  follow_job = ->
    search_action(robot, follow)

  job = new cronJob
    cronTime: "0 15,45 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      follow_job()
