passport = require 'passport'
express = require("express")
router = express.Router()
config = require("./config")
fs = require 'fs'
bodyparser = require 'body-parser'
User = require "./user"

BasicStrategy = (require 'passport-http').BasicStrategy
LocalStrategy = (require 'passport-local').Strategy

passport.serializeUser (user, done) ->
    done null, user

passport.deserializeUser (user, done) ->
    done null, user

class Authentication

    @ensureAuthenticated: (req, res, next) =>
        if req.isAuthenticated()
            return next()
        if req.baseUrl == '/api'
            res.status(401).send()
        else
            res.redirect '/login'

    @init: () =>
        try
            passport.use new LocalStrategy (username, password, done) =>
                user = new User username, password
                user.authenticate done
        catch ex
            return
            
    @initialize: (app) =>
        @users = []
        @init()
        app.use bodyparser.urlencoded({ extended: false })
        app.use bodyparser.json()
        app.use passport.initialize()
        app.use passport.session()
        app.use router

    @authenticate: (req, res, next) =>
        return passport.authenticate('local', { successRedirect: '/', failureRedirect: '/login'})(req, res, next)

router.get '/login', (req, res) ->
    res.render 'login'

router.get '/logout', (req, res) ->
    req.logout()
    res.redirect '/'

router.post '/login', (req, res, next) ->
    Authentication.authenticate(req ,res, next)

module.exports = Authentication
