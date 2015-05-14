express = require("express")
router = express.Router()
passport = require 'passport'
config = require("./config")

require("source-map-support").install()
auth = require './authentication'

# GET home page.
router.get "/"
    , auth.ensureAuthenticated
, (req, res) ->
    res.sendFile 'index.html', { root: config.projectRoot() + '/static/pages' }

module.exports = router
