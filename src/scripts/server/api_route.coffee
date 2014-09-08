express = require("express")
router = express.Router()
DataProviderConnector = require("./data_provider_connector")
ServiceConfig = require('./svcconfig_connector')
FieldData = require './fieldData'
log = require 'loglevel'
log.setLevel 'debug'

require('source-map-support').install()

serviceConfig = ServiceConfig.getInstance()
providers = {}

getDataProvider = (providerId) ->
    if not providers[providerId]?
        adresses = serviceConfig.getAddresses providerId
        metaDataAddress = adresses["META_DATA"]["REQ_REP"][0]
        columnAddress = adresses["COLUMN"]["PUB_SUB"][0]
        queryAddress = adresses["QUERY"]["PUSH_PULL"][0]

        dataProvider = new DataProviderConnector(metaDataAddress, columnAddress, queryAddress)
        providers[providerId] = dataProvider
    return providers[providerId]

# GET home page.
router.get "/", (req, res) ->
  res.json "{message: virtdb api}"
  return

router.get "/endpoints", (req, res) ->
    res.json serviceConfig.getEndpoints()

# GET /data_providers/
router.get "/data_providers/:provider_id/meta_data", (req, res) ->
    providerId = req.params.provider_id

    onMetaDataReceived = (metaData) ->
      res.json metaData
      return

    try
        getDataProvider(providerId).getMetadata "data", ".*", onMetaDataReceived
    catch ex
        res.status(500).send "Error occured: " + ex
        return

router.get "/data_providers/:provider_id/data/table/:table/fields/:fields/count/:count", (req, res) ->
    providerId = req.params.provider_id
    table = req.params.table
    fieldNames = req.params.fields.split ','
    count = req.params.count

    columnData = {}

    onDataReceived = (data) =>
        columnData[data.Name] = FieldData.get(data)
        if checkReceivedColumns()
            res.json columnData
        return

    checkReceivedColumns = () =>
        for field in fieldNames
            if not columnData[field]?
                return false
        return true

    onMetaDataReceived = (metaData) =>
        fields = (field for field in metaData.Tables[0].Fields when field.Name in fieldNames)
        getDataProvider(providerId).getData table, fields, count, onDataReceived, res
        return

    getDataProvider(providerId).getMetadata "data", "^" + table + "$", onMetaDataReceived
    return

# GET /data_providers/:provider_id/meta_data
# GET /data_providers/:provider_id/config
# PUT /data_providers/:provider_id/config
# GET /data_providers/:provider_id/data/:range

module.exports = router
