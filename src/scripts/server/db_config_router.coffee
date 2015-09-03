router = require('express').Router();
DBConfig = require './db_config_connector'
validator = require "./validator"
UserManager = require './user_manager'
User = require './user'
auth = require './authentication'
timeout = require "connect-timeout"
Config = require "./config"
Metadata = require "./meta_data_handler"
log = (require "virtdb-connector").log
V_ = log.Variable

router.get "/users"
, auth.ensureAuthenticated
, timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    DBConfig.listUsers (err, users) ->
        if err?
            res.status(500).send()
            return
        res.json users

router.post "/users"
, auth.ensureAuthenticated
, validator(
        name:
            required: true
        password:
            required: true
        isAdmin:
            required: true
  )
, timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    username = req.body.name
    password = req.body.password
    isAdmin = req.body.isAdmin
    UserManager.updateUser username, password, isAdmin, req.user.token, (err, data) =>
        if not err?
            DBConfig.createUser username, password, (err, data) ->
                if err?
                    res.status(500).send()
                    return
                res.status(200).send()
        else
            res.status(500).send()

router.get "/tables"
, auth.ensureAuthenticated
, validator(
        provider:
            required: true
    , "query")
, timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    provider = req.query.provider
    try
        username = null
        if Config.Features.Security
            username = req.user.name
        DBConfig.getTables provider, username, (tableList) =>
            res.json tableList
    catch ex
        log.error V_(ex)
        throw ex

router.post "/tables"
, auth.ensureAuthenticated
, validator(
        provider:
            required: true
        table:
            required: true
    )
, timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    table = req.body.table
    provider = req.body.provider
    try
        addTable = (token, username, addTableCallback) ->
            Metadata.getTableDescription provider, table, token, (err, metaData) ->
                if err?
                    res.status(500).send()
                    return
                DBConfig.addTable provider, metaData, username, (err) ->
                    if not err?
                        addTableCallback?()
                        res.status(200).send()
                    else
                        res.status(500).send()

        if Config.Features.Security
            User.getTableToken req.user, provider, (err, token) ->
                if not err?
                    addTable token, req.user.name, ->
                        DBConfig.addUserMapping provider, req.user.name, token
        else
            addTable()

        return
    catch ex
        log.error V_(ex)
        throw ex

router.delete "/tables"
, auth.ensureAuthenticated
, validator(
        provider:
            required: true
        table:
            required: true
    , "query")
, timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    table = req.query.table
    provider = req.query.provider
    try
        deleteTable = (token, username) ->
            Metadata.getTableDescription provider, table, token, (err, metaData) ->
                if err?
                    res.status(500).send()
                    return
                DBConfig.deleteTable provider, metaData, username, (err) ->
                    if not err?
                        res.status(200).send()
                    else
                        res.status(500).send()
        if Config.Features.Security
            User.getTableToken req.user, provider, (err, token) ->
                if not err?
                    deleteTable token, req.user.name
        else
            deleteTable()
    catch ex
        log.error V_(ex)
        throw ex

module.exports = router
