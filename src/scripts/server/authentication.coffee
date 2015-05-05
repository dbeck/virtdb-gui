passport = require 'passport'
express = require("express")
router = express.Router()
config = require("./config")
fs = require 'fs'
bodyparser = require 'body-parser'

BasicStrategy = (require 'passport-http').BasicStrategy
GithubStrategy = (require 'passport-github').Strategy
LocalStrategy = (require 'passport-local').Strategy
FacebookStrategy = (require 'passport-facebook').Strategy

passport.serializeUser (user, done) ->
    done null, user

passport.deserializeUser (user, done) ->
    done null, user

class Authentication
    @isEnabled: =>
        for method of @methods
            if @methods[method] then return true
        return false

    @ensureAuthenticated: (req, res, next) =>
        if not @isEnabled() or req.isAuthenticated()
            return next()
        if req.baseUrl == '/api'
            res.status(401).send()
        else
            res.redirect '/login'

    @initGithub: =>
        try
            githubSettings = JSON.parse fs.readFileSync config.projectRoot()+ '/github.json'
            passport.use new GithubStrategy githubSettings
            , (accessToken, refreshToken, profile, done) =>
                @findByUserName profile.username, (err, user) ->
                    if not err? and user?
                        user = profile
                    done err, user
            @methods.github = true
        catch ex
            return

    @initLocal: () =>
        try
            localSettings = JSON.parse fs.readFileSync config.projectRoot()+ '/local.json'
            passport.use new LocalStrategy (username, password, done) =>
                @findByUserName username, (err, user) =>
                    if user?.password is password 
                        done(null, user)
                    else 
                        done(null, false, { message: 'Incorrect username of password' })
            @methods.local = true
        catch ex
            return

    @initSecurityService: () =>
        try
            localSettings = JSON.parse fs.readFileSync config.projectRoot()+ '/security-service.json'
            passport.use new LocalStrategy (username, password, done) =>
                user = new User username, password
                user.authenticate done
            @methods.securityService = true
        catch ex
            return

    @initFacebook: =>
        try
            facebookSettings = JSON.parse fs.readFileSync config.projectRoot()+ '/facebook.json'
            passport.use new FacebookStrategy facebookSettings
            , (accessToken, refreshToken, profile, done) =>
                for user in @users
                    if user.facebookid is profile.id
                        profile.username = user.username
                        return done null, profile
                done null, null
            @methods.facebook = true
        catch ex
            return
            
    @initalize: (app) =>
        @methods =
            github: false
            local: false
        @users = []
        try
            authFile = config.getCommandLineParameter 'authFile'
            @users = JSON.parse fs.readFileSync authFile
        catch ex
            console.error ex
        # @initGithub()
        # @initFacebook()
        # @initLocal()
        @initSecurityService()
        app.use bodyparser.urlencoded({ extended: false })
        app.use bodyparser.json()
        app.use passport.initialize()
        app.use passport.session()
        app.use router

    @findByUserName: (username, callback) =>
        for user in @users
            if user.username is username
                return callback null, user
        callback null, null

    @authenticateLocal: (req, res, next) =>
        if @methods.local
            return passport.authenticate('local', { successRedirect: '/', failureRedirect: '/login'})(req, res, next)
        else
            console.log "This method is not enabled"
            res.redirect '/'

    @authenticateGithub: (req, res, next) =>
        console.log req.body
        console.log req.params
        if @methods.github
            return passport.authenticate('github')(req, res, next)
        next()

    @authenticateFacebook: (req, res, next) =>
        if @methods.facebook
            return passport.authenticate('facebook')(req, res, next)
        next()

router.get '/login', (req, res) ->
    res.render 'login'

router.get '/logout', (req, res) ->
    req.logout()
    res.redirect '/'

router.post '/login', (req, res, next) ->
    Authentication.authenticateLocal(req ,res, next)

router.get '/login/github'
    , Authentication.authenticateGithub
, (req, res) ->
    console.log "This method is not enabled."
    res.redirect '/'

router.get '/login/facebook'
    , Authentication.authenticateFacebook
, (req, res) ->
    console.log "This method is not enabled."
    res.redirect '/'

router.get '/auth/github/callback'
    , passport.authenticate('github', { failureRedirect: '/login' })
, (req, res) ->
    res.redirect '/'

router.get '/auth/facebook/callback'
    , passport.authenticate('facebook', { failureRedirect: '/login' })
, (req, res) ->
    res.redirect '/'

module.exports = Authentication
