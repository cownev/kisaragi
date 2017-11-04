const cronJob        = require('cron').CronJob
const twitter        = require('twitter')
const mongodb        = require('mongodb')
const moment         = require('moment')
const tweet_searcher = require('../lib/tweet_searcher')
const user_filter    = require('../lib/user_filter')

module.exports = function(robot) {
  const twit_client = new twitter({
    consumer_key:        process.env.HUBOT_TWITTER_KEY,
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET,
    access_token_key:    process.env.HUBOT_TWITTER_TOKEN,
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET
  });
  const mongo       = mongodb.MongoClient;
  const mongo_url   = process.env.MONGODB_URI;


  const follow = async function(user) {
    try {
      let db =  await mongo.connect(mongo_url);

      const doc = await db.collection('users').findOne({"twitter_id": user.id_str, "type": {$in: ['ng', 'self']}});
      if(doc) return;

      const result = await twit_client.post('friendships/create', {user_id: user.id_str});
      if(result.following) {
        robot.logger.info(`skipped follow request due to followed user: ${user.screen_name} - ${user.id}`);
        return;
      }

      await db.collection('users').updateOne({'twitter_id': user.id_str, 'type': 'followed'}, {$set: {'ts': moment().unix()}, $inc: {'count': 1}}, {upsert: true});
      robot.logger.info(`followed: ${user.screen_name} - ${user.id}`);
    }
    catch(err) {
      robot.logger.error(`${err}`);
    }
  };


  const search_user = async function(keywords, err) {
    if (err != null) {
      robot.logger.error(`${err}`);
    }　
    else {
      try {
        robot.logger.info(`follow search keywords: ${keywords}`);

        const tweets = await twit_client.get('search/tweets', {q: keywords, count: 10});
        for(let tweet of tweets.statuses) { follow(tweet.user); }
      }
      catch(err) {
        robot.logger.error(`${err}`);
      }
    }
  };

  const follow_job = function() {
    tweet_searcher('event_search', search_user);
  };

  const job = new cronJob({
    cronTime: "0 15,45 * * * *",
    start: true,
    timeZone: "Asia/Tokyo",
    onTick: function() {
      return follow_job();
    }
  });

};
