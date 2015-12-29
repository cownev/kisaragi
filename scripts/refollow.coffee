twit = require('twit')

module.exports = (robot) ->
  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET

  client = new twit keys

#  client.get "account/verify_credentials", (err, data, response) ->
#    stream = client.stream 'user'

#    stream.on 'follow', (event) ->
#      if data? and data.id isnt event.source.id
#        client.post 'friendships/create', {user_id: event.source.id}, (err, data, response) ->
#          if err?
#            robot.logger.error "#{err}"
#          else
#            robot.logger.info "refollowed #{event.source.screen_name}"
