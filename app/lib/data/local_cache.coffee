# LocalCache REQUIRES
# - name: a domain name
# - remote.get: a function to get batches of missing data by ids
# => SHOULD output an indexed collection: {id1: {val}, id2: {val}}
# - parseData: a function to parse the remote.get


# RETURNS
# an object with a .get function checking local before remote
# .get:
#     accepts both id:String or ids:Array
#     always return an index {id1: value, id2: value}
#

module.exports = (LocalDB, _, promises_)->

  LocalCache = (options)->
    _.log options, 'cache:options'
    {name, remote, parseData} = options
    _.types [name, remote], ['string', 'object']

    localdb = LocalDB(name)

    defaultParser = (data)-> data
    parseData or= defaultParser


    API =
      get: (ids, format='index', refresh)->
        try ids = normalizeIds(ids)
        catch err then return Promise.reject(err)

        if refresh
          promise = getMissingData(ids)
        else
          promise = getLocalData(ids).then completeWithRemoteData

        return promise
        .then (data)->
          _.type data, 'object'
          if format is 'collection' then data = _.values(data)
          _.log data, "cache:format:#{format}"
        .catch (err)->
          _.error err, 'local cache err'
          return

      save: (id, value)->
        _.types arguments, ['string', 'object']
        _.log "cache:saving #{id}"
        putInLocalDb id, value

      reset: -> localdb.destroy()
      db: localdb

    normalizeIds = (ids)->
      # formatting ids arrays for LevelMultiply
      # thus normalizing the answer as an id-based index object
      _.type ids, 'string|array'
      if _.isString(ids) then ids = [ids]
      return ids

    getLocalData = (ids)->
      # _.type ids, 'array' asserted by normalizeIds
      localdb.get(ids)
      .then parseJSON
      .then (data)-> _.log data, "cache:#{name} present"

    parseJSON = (data)->
      # LevelJs returns a json string per item
      # while LevelMultiply regroup them in an id-based index object
      # thus requiring every value to be JSON.parse'd
      _.type data, 'object'
      parsed = {}
      for k,v of data
        try parsed[k] = JSON.parse(v)
        catch err then _.error "invalid json: #{v}"
      return parsed

    completeWithRemoteData = (data)->
      _.type data, 'object'
      missingIds = findMissingIds(data)
      _.log missingIds, "cache:#{name} missingIds"
      if missingIds.length > 0
        getMissingData(missingIds)
        .then (missingData)-> return _.extend data, missingData
      else return data

    findMissingIds = (data)->
      _.type data, 'object'
      missingIds = []
      for k, v of data
        missingIds.push(k)  unless v?
      return missingIds

    getMissingData = (ids)->
      _.type ids, 'array'
      # which MUST return a {id1: value2, id2: value2, ...} object
      promise = remote.get(ids).then parseData

      unless promise?.then? then throw new Error('couldnt get missing data')

      # cachedData is listening to the remote data
      # but doesn't need to be returned elsewhere
      promise.then putLocalData
      return promise

    putLocalData = (data)->
      _.type data, 'object'
      for id, v of data
        putInLocalDb(id,v)
      return data

    putInLocalDb = (id, value)->
      localdb.put id, JSON.stringify(value)


    if remote.post?
      API.post = (data)->
        remote.post(data)
        .then putLocalData
        .catch (err)-> _.error err, "#{name} local.post err"

    _.extend @, API
    return