cronJob       = require('cron').CronJob
twit          = require('twit')
search_action = require('../lib/search_action')
user_filter   = require('../lib/user_filter')

module.exports = (robot) ->
  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET

  twit_client    = new twit keys
  retweeted_uids = []

  post = (tweets) ->
    if !tweets.length
      robot.logger.info "did not find any tweets for retweet"
      return

    else
      tweet = tweets[0]

      if retweeted_uids.length >= 72
        retweeted_uids.length = 0
        robot.logger.info "reset retweeted_uids"

      user_filter(tweet.user.id, (ng_flag, err) ->
        if err?
          robot.logger.error "#{err}"
          return

        else if !ng_flag
          unless tweet.user.id_str in retweeted_uids
            twit_client.post 'statuses/retweet/:id', { id: tweet.id_str }, (err, data, response) ->
              if err?
                robot.logger.error "#{err} #{tweet.user.screen_name}'s #{tweet.id_str}"
                tweets.shift()
                return post(tweets)

              else
                robot.logger.info "retweeted #{tweet.user.screen_name}'s #{tweet.id_str}"
                retweeted_uids.push(tweet.user.id_str)

              robot.logger.info "retweeted_uids counter: #{retweeted_uids.length}"
              return

          else
            robot.logger.info "did not retweet because #{tweet.user.id} is in retweeted_uids"
            tweets.shift()
            return post(tweets)

        else
          robot.logger.info "did not retweet because #{tweet.user.id} is ng id"
          tweets.shift()
          return post(tweets)
        )

  retweet = (keywords) ->
    robot.logger.info "retweet search keywords: '#{keywords}'"
    twit_client.get 'search/tweets', { q: "#{keywords}", count: 5, result_type: "mixed"}, (err, data, response) ->
      post(data.statuses)

  retweet_job = ->
    search_action(robot, retweet)

  job = new cronJob
    cronTime: "0 10,50 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      retweet_job()
