mongodb = require('mongodb')

mongo     = mongodb.MongoClient
mongo_url = process.env.MONGODB_URI

module.exports = (uid, callback) ->
    mongo.connect(mongo_url, (err, db) ->
      if err?
        callback(null, err)

      else
        collection = db.collection 'users'

        collection.findOne(({"twitter_id":uid, "type":{$in:['ng','self']}}), (err, doc) ->
          if err?
            flag = null

          else
            flag = if doc? then true else false

          callback(flag, err)
        )
    )
