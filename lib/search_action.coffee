mongodb = require('mongodb')

mongo     = mongodb.MongoClient
mongo_url = process.env.MONGODB_URL

module.exports = (robot, callback) ->
    mongo.connect(mongo_url, (err, db) ->
      if err?
        robot.logger.error "#{err}"
      else
        collection = db.collection 'ngs'
        keywords   = "#イベント"

        collection.find({"keyword": {$exists:true}}).each( (err, doc) ->
          if err?
            robot.logger.error "#{err}"
          else if doc?
            keyword = " " + "-\"" + doc.keyword + "\""
            keywords += keyword
          else
            callback(keywords)
        )
    )
