queryIdCounter = 0
MAX_QUERY_ID = 100000

getNextQueryId = ->
    (queryIdCounter++ % MAX_QUERY_ID).toString()

module.exports =
    getNextQueryId: getNextQueryId
    MAX_QUERY_ID: MAX_QUERY_ID
