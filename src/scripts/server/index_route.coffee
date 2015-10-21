express = require 'express'
router = express.Router()
passport = require 'passport'
config = require './config'
Authentication = require './authentication'
Installer = require './installer'
CacheHandler = require './cache_handler'

require("source-map-support").install()
auth = require './authentication'

serveHtml = (res, name) ->
    res.sendFile "#{name}.html", { root: config.projectRoot() + '/static/pages' }

# Make sure VirtDB Gui is installed
ensureInstalled = (req, res, next) ->
    if config.Features.Installer and not config.isInstalled()
        res.redirect '/welcome'
    else
        next()

# GET home page.
router.get "/"
    , ensureInstalled
    , auth.ensureAuthenticated
, (req, res) ->
    serveHtml res, 'index'

router.get "/welcome", (req, res) ->
    if not config.Features.Installer
        res.redirect '/'
        return
    serveHtml res, 'welcome'

router.get '/login'
    , ensureInstalled
, (req, res) ->
    if not config.Features.Security
        res.redirect '/'
        return
    serveHtml res, 'login'

router.get '/logout', (req, res) ->
    CacheHandler.reset()
    req.logout()
    res.redirect '/'

router.post '/login', (req, res, next) ->
    Authentication.authenticate(req ,res, next)

router.post '/install', (req, res, next) ->
    try
        Installer.process req.body, ->
            res.redirect '/'
    catch ex
        res.sendStatus 500

module.exports = router
