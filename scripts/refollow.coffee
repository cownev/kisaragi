twit = require('twit')

module.exports = (robot) ->
  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET

  twit_client = new twit keys

#  twit_client.get "account/verify_credentials", (err, data, response) ->
#    stream = twit_client.stream 'user'

#    stream.on 'follow', (event) ->
#      if data? and data.id isnt event.source.id
#        twit_client.post 'friendships/create', {user_id: event.source.id}, (err, data, response) ->
#          if err?
#            robot.logger.error "#{err}"
#          else
#            robot.logger.info "refollowed #{event.source.screen_name}"
