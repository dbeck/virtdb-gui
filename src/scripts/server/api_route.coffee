express = require("express")
router = express.Router()
MetadataConnector = require("./meta_data_connector")
ServiceConfig = require('./svcconfig_connector')

require('source-map-support').install()

serviceConfig = ServiceConfig.getInstance()

# GET home page.
router.get "/", (req, res) ->
  res.json "{message: virtdb api}"
  return

router.get "/endpoints", (req, res) ->
    res.json serviceConfig.getEndpoints()

# GET /data_providers/
router.get "/data_providers/:provider_id/meta_data", (req, res) ->
    provider_id = req.params.provider_id
    adresses = serviceConfig.getAddress provider_id, 'META_DATA', 'REQ_REP'

    onMetaDataReceived = (metaData) ->
      res.json metaData
      return

    dataProvider = new MetadataConnector()
    dataProvider.connect(adresses[0])
    dataProvider.getMetadata "data", ".*", onMetaDataReceived
    return

# GET /data_providers/:provider_id/meta_data
# GET /data_providers/:provider_id/config
# PUT /data_providers/:provider_id/config
# GET /data_providers/:provider_id/data/:range

module.exports = router
