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

      user_filter(tweet.user.id_str, (ng_flag, err) ->
        if err?
          robot.logger.error "#{err}"
          return

        else if !ng_flag
          unless tweet.user.id_str in retweeted_uids
            twit_client.post 'statuses/retweet/:id', { id: tweet.id_str }, (err, data, response) ->

              retweeted_uids.push(tweet.user.id_str)
              robot.logger.info "added to retweeted_uids: #{tweet.user.screen_name}"
              robot.logger.info "retweeted_uids counter : #{retweeted_uids.length}"

              if err?
                robot.logger.error "#{err} #{tweet.user.screen_name}'s #{tweet.id_str}"
                tweets.shift()
                return post(tweets)

              robot.logger.info "retweeted #{tweet.user.screen_name}'s #{tweet.id_str}"
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

  retweet = (keywords, err) ->
    if err?
      robot.logger.error "#{err}"
    else
      robot.logger.info "retweet search keywords: '#{keywords}'"
      twit_client.get 'search/tweets', { q: "#{keywords}", count: 5, result_type: "mixed"}, (err, data, response) ->
        post(data.statuses)
    return

  retweet_job = ->
    switch new Date().getMinutes()
      when 30
        search_word = 'anniversary_search'
      else
        search_word = 'event_search'

    tweet_searcher(search_word, retweet)
    return

  job = new cronJob
    cronTime: "0 10,30,50 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      retweet_job()
