mongodb = require('mongodb')

mongo     = mongodb.MongoClient
mongo_url = process.env.MONGODB_URL

module.exports = (uid, callback) ->
    mongo.connect(mongo_url, (err, db) ->
      if err?
        callback(null, err)

      else
        collection = db.collection 'users'

        collection.findOne(({"twitter_id": uid, "$or":[{ "ng": true}, { "self": true}]}), (err, doc) ->
          if err?
            flag = null

          else if doc?
            flag = true

          else
            flag = false

          callback(flag, err)
        )
    )
