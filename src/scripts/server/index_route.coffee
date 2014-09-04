express = require("express")
router = express.Router()
ServiceConfigConnector = require("./svcconfig_connector")
MetadataConnector = require("./meta_data_connector")
require('source-map-support').install()

# GET home page.
router.get "/", (req, res) ->
  res.render 'index'

module.exports = router
