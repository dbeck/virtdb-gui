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
Features = Config.Features

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
        DBConfig.getTables provider, username, (list) ->
            res.json list
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
        if Config.Features.Security
            User.getTableToken req.user, provider, (err, token) ->
                if not err?
                    addTable provider, table, token, req.user.name, false, (err) ->
                        unless err?
                            res.sendStatus 200
                            DBConfig.addUserMapping provider, req.user.name, token
                            return
                        res.sendStatus 500
        else
            addTable provider, table, null, null, false, (err) ->
                if err?
                    res.sendStatus 500
                else
                    res.sendStatus 200
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
        if Config.Features.Security
            User.getTableToken req.user, provider, (err, token) ->
                if not err?
                    deleteTable provider, table, token, req.user.name, false, (err) ->
                        if err?
                            res.sendStatus 500
                        else
                            res.sendStatus 200
        else
            deleteTable provider, table, null, null, false, (err) ->
                if err?
                    res.sendStatus 500
                else
                    res.sendStatus 200
    catch ex
        log.error V_(ex)
        throw ex

if Features.Materialization
    router.post "/tables/materialize"
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
            if Config.Features.Security
                User.getTableToken req.user, provider, (err, token) ->
                    if not err?
                        addTable provider, table, token, req.user.name, true, (err) ->
                            unless err?
                                res.sendStatus 200
                                DBConfig.addUserMapping provider, req.user.name, token
                                return
                            res.sendStatus 500
            else
                addTable provider, table, null, null, true, (err) ->
                    if err?
                        res.sendStatus 500
                    else
                        res.sendStatus 200
            return
        catch ex
            log.error V_(ex)
            throw ex

    router.delete "/tables/materialize"
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
            if Config.Features.Security
                User.getTableToken req.user, provider, (err, token) ->
                    if not err?
                        deleteTable provider, table, token, req.user.name, true, (err) ->
                            if err?
                                res.sendStatus 500
                            else
                                res.sendStatus 200
            else
                deleteTable provider, table, null, null, true, (err) ->
                    if err?
                        res.sendStatus 500
                    else
                        res.sendStatus 200
        catch ex
            log.error V_(ex)
            throw ex

addTable = (provider, table, token, username, materialize, addTableCallback) ->
    Metadata.getTableDescription provider, table, token, (err, metaData) ->
        if err?
            log.error "Couldn't add table because error happened during getting metadata.", (V_ err)
            addTableCallback err
            return
        metaData.Tables[0].Properties.push
            Key: "materialize"
            Value:
                Type: "BOOL"
                BoolValue: [materialize]
        DBConfig.addTable provider, metaData, username, addTableCallback

deleteTable = (provider, table, token, username, materialize, deleteTableCallback) ->
    Metadata.getTableDescription provider, table, token, (err, metaData) ->
        if err?
            log.error "Couldn't delete table because error happened during getting metadata.", (V_ err)
            deleteTableCallback err
            return
        metaData.Tables[0].Properties.push
            Key: "materialize"
            Value:
                Type: "BOOL"
                BoolValue: [materialize]
        DBConfig.deleteTable provider, metaData, username, deleteTableCallback

module.exports = router
