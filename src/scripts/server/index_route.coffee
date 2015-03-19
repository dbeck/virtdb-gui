express = require("express")
router = express.Router()
passport = require 'passport'

require("source-map-support").install()

# GET home page.
router.get "/"
    , passport.authenticate('basic', { session: false })
, (req, res) ->
  res.render "index"

module.exports = router
