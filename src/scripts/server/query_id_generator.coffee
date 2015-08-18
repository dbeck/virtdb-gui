queryIdCounter = 0

QueryIdGenerator =
    MAX_QUERY_ID: 100000
    getNextQueryId: ->
        (queryIdCounter++ % QueryIdGenerator.MAX_QUERY_ID).toString()

module.exports =
    QueryIdGenerator
