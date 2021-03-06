books_ = sharedLib('books')(_)

books_.getImage = (data)->
  images.push data
  lazyGetImages()
  return eventName(data)

images = []
eventName = (data)-> "image:#{data}"
getImages = ->
  _.log 'querying image'
  _.preq.get app.API.entities.getImages(images)
  .then (res)->
    _.log res, 'data:getImages res'
    if res? and _.isArray(res)
      res.forEach (el)->
        if el?
          app.vent.trigger eventName(el.data), el.image
    images = []
  .catch (err)-> _.logXhrErr err, "getImages err for images: #{images}"

lazyGetImages = _.debounce getImages, 100


books_.getIsbnEntities = (isbns)->
  isbns = isbns.map books_.normalizeIsbn
  _.preq.get app.API.entities.isbns(isbns)
  .catch (err)-> _.logXhrErr err, 'getIsbnEntities err'

module.exports = books_