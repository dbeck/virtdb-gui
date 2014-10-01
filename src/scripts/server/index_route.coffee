express = require("express")
router = express.Router()

require("source-map-support").install()

# GET home page.
router.get "/", (req, res) ->
  res.render "index"

module.exports = router
