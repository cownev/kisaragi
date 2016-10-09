cronJob        = require('cron').CronJob
twit           = require('twit')
tweet_searcher = require('../lib/tweet_searcher')
user_filter    = require('../lib/user_filter')

module.exports = (robot) ->
  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET

  twit_client = new twit keys

  follow = (keywords, err) ->
    if err?
      robot.logger.error "#{err}"
    else
      robot.logger.info "follow search keywords: '#{keywords}'"

      twit_client.get 'search/tweets', { q: "#{keywords}", count: 10 }, (err, data, response) ->
        data.statuses.forEach (tweet) ->
          user_filter(tweet.user.id_str, (ng_flag, err) ->
            if err?
              robot.logger.error "#{err}"
            else if !ng_flag
              twit_client.post 'friendships/create', {user_id: tweet.user.id}, (err, data, response) ->
                if err?
                  robot.logger.error "#{err}"
                else
                  robot.logger.info "followed #{tweet.user.screen_name}"
                return
            return
          )
    return

  follow_job = ->
    tweet_searcher('event_search', follow)
    return

  job = new cronJob
    cronTime: "0 15,45 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      follow_job()
