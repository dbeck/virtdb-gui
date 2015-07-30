require './monitoring'
require './certificates'
router = require './router'
util = require "util"
DBConfig = require "./db_config_connector"
Config = require "./config"
VirtDBConnector = require "virtdb-connector"
VirtDBLoader = require "./virtdb_loader"
KeyValue = require "./key_value"
ConfigService = require "./config_service"
DiagConnector = require "./diag_connector"
User = require './user'
timeout = require "connect-timeout"
log = VirtDBConnector.log
V_ = log.Variable
Endpoints = require "./endpoints"
auth = require './authentication'
validator = require "./validator"

DataHandler = require "./data_handler"
MetadataHandler = require "./meta_data_handler"
Authentication = require "./authentication"
TokenManager = VirtDBConnector.TokenManager
Credentials = require "./credentials"

require('source-map-support').install()

router.use require 'express-domain-middleware'

router.get /.*/, (req, res, next) =>
    VirtDBConnector.MonitoringService.bumpStatistic "HTTP request arrived"
    next()

router.use '/user', (require './user_router')

# GET home page.
router.get "/"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    res.json "{message: virtdb api}"
    return

router.get "/features", (req, res) ->
    res.json Config.Features

router.get "/settings", (req, res) ->
    res.json Config.Settings

router.get "/authmethods"
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    res.json Authentication.methods

router.get "/endpoints"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    try
        if not res.headersSent
            res.json Endpoints.getCompleteEndpointList()
    catch ex
        log.error V_(ex)
        throw ex

router.post "/data_provider/meta_data/"
    , auth.ensureAuthenticated
    , validator("/data_provider/meta_data",
        provider:
            required: true
        table:
            required: true
    )
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    provider = req.body.provider
    table = req.body.table
    id = if req.body.id? then Number req.body.id else 0
    onMetadata = (err, metadataMessage) ->
        if err?
            res.status(500).send()
            return
        metaData = metadataMessage.Tables[0]
        if not res.headersSent
            for field in metaData.Fields
                properties = {}
                for prop in field.Properties
                    formattedProp = KeyValue.toJSON prop
                    for key, value of formattedProp
                        properties[key] = value
                field.Properties = properties
            response =
                data: metaData
                id: id
            res.json response

    try
        token = req?.user?.token
        metadataHandler = new MetadataHandler()
        metadataHandler.getTableMetadata provider, table, token, onMetadata
    catch ex
        log.error V_(ex)
        throw ex

router.get "/data_provider/list"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    try
        if not res.headersSent
            res.json Endpoints.getDataProviders()
    catch ex
        log.error V_(ex)
        throw ex

router.post "/data_provider/table_list"
    , auth.ensureAuthenticated
    , validator("/data_provider/table_list",
        provider:
            required: true
        from:
            required: true
        to:
            required: true
    )
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) =>
    provider = req.body.provider
    from = Number req.body.from
    to = Number req.body.to
    search = req.body.search
    id = if req.body.id? then Number req.body.id else 0
    tablesToFilter = req.body.tables

    try
        token = req?.user?.token
        metadataHandler = new MetadataHandler()
        metadataHandler.getTableList provider, search, from, to, tablesToFilter, token, (err, result) ->
            if err?
                res.status(500).send()
                return
            response =
                data: result
                id: id
            if not res.headersSent
                res.json response
            return
    catch ex
        log.error V_(ex)
        throw ex


router.post "/data_provider/data"
    , auth.ensureAuthenticated
    , validator("/data_provider/data",
        provider:
            required: true
        table:
            required: true
        count:
            required: true
            validate: (value) ->
                value > 0 and value <= 100
    )
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    try
        dataHandler = null
        req.on 'timeout', ->
            dataHandler?.cleanup()
        provider = req.body.provider
        table = req.body.table
        count = req.body.count
        id = if req.body.id? then Number req.body.id else 0
        onData = (data) ->
            if not res.headersSent
                if data.length is 0
                    res.json {
                        id: id
                        data: []
                    }
                    return
                dataRows = []
                firstColumn = data[0].Data
                if firstColumn.length > 0
                    for i in [0..firstColumn.length-1]
                        dataRows.push data.map( (column) ->
                            fieldValue = column?.Data[i]
                            fieldValue ?= "null"
                        )
                res.json {
                    id: id
                    data: dataRows
                }

        token = req?.user?.token
        dataHandler = new DataHandler
        dataHandler.getData token, provider, table, count, onData
    catch ex
        log.error V_(ex)
        throw ex

router.post "/db_config/get"
    , auth.ensureAuthenticated
    , validator("/data_provider/data",
        provider:
            required: true
    )
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    provider = req.body.provider
    try
        username = null
        if Config.Features.Security
            username = req.user.name
        DBConfig.getTables provider, username, (tableList) =>
            res.json tableList
    catch ex
        log.error V_(ex)
        throw ex

router.get "/db_config/list_users"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    DBConfig.listUsers (err, users) ->
        if err?
            res.status(500).send()
            return
        res.json users

#router.post "/db_config/add_user"
#    , auth.ensureAuthenticated
#    , timeout(Config.getCommandLineParameter("timeout"))
#, (req, res, next) ->
#    DBConfig.listUsers (err, users) ->
#        if err?
#            res.status(500).send()
#            return
#        res.json users

router.post "/db_config/add"
    , auth.ensureAuthenticated
    , validator("/data_provider/data",
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
        addTable = (token, username) ->
            metadataHandler = new MetadataHandler()
            metadataHandler.getTableMetadata provider, table, token, (err, metaData) ->
                if err?
                    res.status(500).send()
                    return
                DBConfig.addTable provider, metaData, username, (err) ->
                    if not err?
                        res.status(200).send()
                    else
                        res.status(500).send()

        if Config.Features.Security
            User.getTableToken req.user, provider, (err, token) ->
                if not err?
                    addTable token, req.user.name
                    DBConfig.addUserMapping provider, req.user.name, token
        else
            addTable()

        return
    catch ex
        log.error V_(ex)
        throw ex

router.post "/db_config/delete"
    , auth.ensureAuthenticated
    , validator("/data_provider/data",
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
        deleteTable = (token, username) ->
            metadataHandler = new MetadataHandler()
            metadataHandler.getTableMetadata provider, table, token, (err, metaData) ->
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

router.get "/get_credential/:component"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) =>
    try
        component = req.params.component
        Credentials.getCredential req.user.token, component, (err, credential) ->
            if err?
                log.error "Error during getting credential", (V_ component), (V_ err)
                res.json {}
                return
            res.json credential
    catch ex
        log.error V_(ex)
        throw ex

router.post "/set_credential/:component"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) =>
    try
        component = req.params.component
        Credentials.setCredential req.user.token, component, req.body, (err) ->
            if err?
                log.error "Cannot set credential", (V_ component), (V_ err)
            res.json {}
    catch ex
        log.error V_(ex)
        throw ex

router.get "/get_config/:component"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) =>
    try
        component = req.params.component
        ConfigService.getConfig component, (config) =>
            if config?
                res.json config
            else
                res.json {}
    catch ex
        log.error V_(ex)
        throw ex

router.post "/set_config/:component"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) =>
    try
        component = req.params.component
        config = req.body

        if ConfigService.sendConfig component, config
            metadataHandler = new MetadataHandler
            metadataHandler.emptyProviderCache component
            if not res.headersSent
                res.status(200).send()
        else
            res.status(400).send("Invalid config.")

    catch ex
        log.error V_(ex)
        throw ex

router.post "/get_diag"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) =>
    try
        from = Number req.body.from
        levels = req.body.levels
        res.json DiagConnector.getRecords from, levels
    catch ex
        log.error V_(ex)
        throw ex

router.use (err, req, res, next) =>
    log.error V_(req.url), V_(req.body), V_(err.message)
    VirtDBConnector.MonitoringService.bumpStatistic "HTTP error happened"
    res.status(if err.status? then err.status else 500).send(err.message)

module.exports = router
