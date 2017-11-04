mongodb = require('mongodb')

mongo     = mongodb.MongoClient
mongo_url = process.env.MONGODB_URI

module.exports = (search, callback) ->
    mongo.connect(mongo_url, (err, db) ->
      if err?
        callback(null, err)
      else
        collection = db.collection 'keywords'
        keywords   = []

        collection.find({"type":{$in:[search,'ng_search']}}).each (err, doc) ->
          if err?
            callback(null, err)
          else if doc?
            keyword = if doc.type is search then doc.keyword else "-\"#{doc.keyword}\""
            keywords.push(keyword)
          else
            callback(keywords.join(" "), err)
        )
