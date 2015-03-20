express = require("express")
router = express.Router()
passport = require 'passport'

require("source-map-support").install()
auth = require './authentication'

# GET home page.
router.get "/"
    , auth.ensureAuthenticated
, (req, res) ->
    res.render "index"

module.exports = router
