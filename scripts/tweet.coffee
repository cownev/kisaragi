cronJob = require('cron').CronJob
twit    = require('twit')
moment  = require('moment')
mongodb = require('mongodb')

module.exports = (robot) ->
  keys =
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET

  twit_client = new twit keys
  mongo       = mongodb.MongoClient
  mongo_url   = process.env.MONGODB_URI


  anomalous_eventday = (event, year) ->
    firstday = moment year + '-' + event.month + '-01'
    weekday  = if firstday.day() > event.weekday then event.weekday + 7 else event.weekday

    return firstday.day weekday + (event.week_num - 1) * 7


  select_event = (events, priority) ->
    today = moment().startOf 'day'

    for event in events

      if event.type is 'anomalous_yearly'
        eventday = anomalous_eventday event, today.year()

      else if event.type is 'yearly'
        eventday = moment today.year()+'-'+event.month+'-'+event.day
        unit     = 'years'

      else if event.type is 'monthly'
        eventday = moment today.format('YYYY-MM-')+event.day
        unit     = 'months'

      if parseInt(eventday.diff today, 'days') < 0
        if  event.type is 'anomalous_yearly'
          eventday = anomalous_eventday event, today.year()+1
        else
          eventday.add(1, unit)

      #robot.logger.info event.name + "-" + eventday.format('YYYY-MM-DD')
      event.days = eventday.diff today, 'days'

    events.sort (a,b) ->
      if a.days<b.days then -1 else if a.days>b.days then 1 else 0

    return events[priority-1]


  tweet = ->
    mongo.connect(mongo_url, (err, db) ->
      if err?
        robot.logger.error "#{err}"

      else
        collection = db.collection 'schedule'
        hour       = new Date().getHours()

        collection.findOne({"hour": hour}, (err, sc) ->
          if err?
            robot.logger.error "#{err}"

          else if sc?
            collection = db.collection 'events'

            collection.find({"active": true}).toArray (err, events) ->
              db.close()

              if err?
                robot.logger.error "#{err}"

              else if events.length > sc.priority
                event    = select_event(events, sc.priority)
                name     = event.name
                days     = event.days
                hashtag  = "#イベント #カウントダウン"

                if days is 0
                  message = "本日は#{name}。\n##{name} #{hashtag}"

                else
                  message = "#{name}まであと#{days}日。\n##{name} #{hashtag}"

                twit_client.post 'statuses/update', {status: message}, (err, data, response) ->
                  if err?
                    robot.logger.error "#{err}"
                  else
                    robot.logger.info "tweet with cron at #{hour}:00"

          else
            db.close()
        )
    )

  tweet_job = ->
    tweet()
    return

  job = new cronJob
    cronTime: "0 0 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      tweet_job()
