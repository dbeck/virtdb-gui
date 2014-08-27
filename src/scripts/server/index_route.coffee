express = require("express")
router = express.Router()
ServiceConfigConnector = require("./svcconfig_connector")
MetadataConnector = require("./meta_data_connector")

# GET home page.
router.get "/", (req, res) ->
  res.render "index"
  return

router.get "/endpoints", (req, res) ->
  onEndpointsReceived = (endpoints) ->
    res.render "endpoints",
        endpoints: endpoints

    return

  svc_config = new ServiceConfigConnector()
  svc_config.connect()
  svc_config.getEndpoints onEndpointsReceived
  return

router.get "/metadata", (req, res) ->
  onMetadata = (metadata) ->
    res.render "metadata",
        tables: metadata.Tables

    return

  metadata = new MetadataConnector()
  schema = "data"
  regexp = ".*"
  metadata.connect req.param("url")
  metadata.getMetadata schema, regexp, onMetadata
  return

module.exports = router
