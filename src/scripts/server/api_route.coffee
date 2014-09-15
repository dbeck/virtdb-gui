express = require("express")
router = express.Router()
DataProviderConnection = require("./data_provider_connector")
ServiceConfig = require('./svcconfig_connector')
FieldData = require './fieldData'
MetaDataCache = require './meta_data_cache'
log = require 'loglevel'
log.setLevel 'debug'

require('source-map-support').install()

serviceConfig = ServiceConfig.getInstance()
providers = {}
metaDataCache = {}

# returns true if table already in metaDataCache false anyway
isTableInCache = (provider, table) =>
    if metaDataCache[provider]?
        return metaDataCache[provider].getTable(table)?
    return false

# create cache for the given provider
prepareCache = (provider) =>
    if not metaDataCache[provider]?
        metaDataCache[provider] = new MetaDataCache()

# getDataProvider = (providerId) ->
#     # if not providers[providerId]?
#         adresses = serviceConfig.getAddresses providerId
#         metaDataAddress = adresses["META_DATA"]["REQ_REP"][0]
#         columnAddress = adresses["COLUMN"]["PUB_SUB"][0]
#         queryAddress = adresses["QUERY"]["PUSH_PULL"][0]
#
#         dataProvider = new DataProviderConnector(metaDataAddress, columnAddress, queryAddress)
#         providers[providerId] = dataProvider
#     return providers[providerId]

# GET home page.
router.get "/", (req, res) ->
  res.json "{message: virtdb api}"
  return

router.get "/endpoints", (req, res) ->
    try
        res.json serviceConfig.getEndpoints()
    catch ex
        log.error ex
        res.status(500).send "Error occured: " + ex

router.get "/data_provider/:provider_id/meta_data/table/:table", (req, res) ->
    provider = req.params.provider_id
    table = req.params.table
    connection = DataProviderConnection.getConnection(provider)

    onMetaDataReceived = (metaData) ->
        res.json metaData.Tables[0]
        prepareCache(provider)
        metaDataCache[provider].putTable(metaData.Tables[0])
        return

    try
        if not isTableInCache(provider, table)
            connection.getMetadata "data", table, true, onMetaDataReceived
        else
            res.json metaDataCache[provider].getTable(table)
    catch ex
        log.error ex
        res.status(500).send "Error occured: " + ex
        return


router.get "/data_provider/:provider_id/meta_data/table_names", (req, res) ->
    provider = req.params.provider_id
    connection = DataProviderConnection.getConnection(provider)

    onMetaDataReceived = (metaData) ->
        res.json (table.Name for table in metaData.Tables)
        connection.close()
        return

    try
        connection.getMetadata "data", ".*", false, onMetaDataReceived
    catch ex
        log.error ex
        res.status(500).send "Error occured: " + ex
        return

router.get "/data_provider/:provider_id/data/table/:table/count/:count", (req, res) ->
    provider = req.params.provider_id
    connection = DataProviderConnection.getConnection(provider)
    table = req.params.table
    count = req.params.count
    columnData = {}
    fieldNames = []

    tableMeta = metaDataCache[provider].getTable(table)

    onDataReceived = (data) =>
        columnData[data.Name] = FieldData.get(data)
        if checkReceivedColumns()
            res.json columnData
        return

    checkReceivedColumns = () =>
        for field in tableMeta.Fields
            if not columnData[field.Name]?
                return false
        return true

    connection.getData table, tableMeta.Fields, count, onDataReceived

    return

# GET /data_providers/:provider_id/meta_data
# GET /data_providers/:provider_id/config
# PUT /data_providers/:provider_id/config
# GET /data_providers/:provider_id/data/:range

module.exports = router
