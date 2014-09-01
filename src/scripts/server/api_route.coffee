express = require("express")
router = express.Router()
ServiceConfigConnector = require("./svcconfig_connector")
MetadataConnector = require("./meta_data_connector")

# GET home page.
router.get "/", (req, res) ->
  res.json "{message: virtdb api}"
  return

router.get "/endpoints", (req, res) ->
  onEndpointsReceived = (endpoints) ->
    res.json endpoints
    return

  svc_config = new ServiceConfigConnector()
  svc_config.connect()
  svc_config.getEndpoints onEndpointsReceived
  return

# GET /data_providers/
router.get "/data_providers/:provider_id/meta_data", (req, res) ->
    provider_id = req.params.provider_id
    console.log provider_id
    onMetaDataReceived = (endpoints) ->
      res.json endpoints
      return

    data_provider = new MetadataConnector()
    data_provider.connect("tcp://127.0.0.1:36891")
    data_provider.getMetadata "data", ".*", onMetaDataReceived
    return

# GET /data_providers/:provider_id/meta_data
# GET /data_providers/:provider_id/config
# PUT /data_providers/:provider_id/config
# GET /data_providers/:provider_id/data/:range

# router.put "/data_providers/:provider_id/config" (req, res) ->
#     res.json "{param: " + req.params.provider_ids

module.exports = router
