passport = require 'passport'
express = require("express")
config = require("./config")
fs = require 'fs'
User = require "./user"

BasicStrategy = (require 'passport-http').BasicStrategy
LocalStrategy = (require 'passport-local').Strategy

passport.serializeUser (user, done) ->
    done null, user

passport.deserializeUser (user, done) ->
    done null, user

class Authentication

    @ensureAuthenticated: (req, res, next) =>
        if not config.Features.Security or req.isAuthenticated()
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
        app.use passport.initialize()
        app.use passport.session()

    @authenticate: (req, res, next) =>
        return passport.authenticate('local', { successRedirect: '/', failureRedirect: '/login'})(req, res, next)

module.exports = Authentication
