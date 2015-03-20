express = require "express"
router = express.Router()
util = require "util"
DBConfig = require "./db_config_connector"
Config = require "./config"
VirtDBConnector = require "virtdb-connector"
VirtDBLoader = require "./virtdb_loader"
KeyValue = require "./key_value"
ConfigService = require "./config_service"
DiagConnector = require "./diag_connector"
timeout = require "connect-timeout"
ok = require "okay"
log = VirtDBConnector.log
V_ = log.Variable
Endpoints = require "./endpoints"
auth = require './authentication'

DataHandler = require "./data_handler"
MetadataHandler = require "./meta_data_handler"
Authentication = require "./authentication"

require('source-map-support').install()

router.use require 'express-domain-middleware'

# GET home page.
router.get "/" 
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    res.json "{message: virtdb api}"
    return

router.get "/authmethods"
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    res.json Authentication.methods

router.get "/user"
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    res.json req.user


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
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    provider = req.body.provider
    table = req.body.table
    id = Number req.body.id
    onMetadata = (metadataMessage) ->
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
        metadataHandler = new MetadataHandler()
        metadataHandler.getTableMetadata provider, table, onMetadata
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
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) =>
    provider = req.body.provider
    from = Number req.body.from
    to = Number req.body.to
    search = req.body.search
    id = Number req.body.id
    tablesToFilter = req.body.tables

    try
        metadataHandler = new MetadataHandler()
        metadataHandler.getTableList provider, search, from, to, tablesToFilter, (result) ->
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
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    try
        provider = req.body.provider
        table = req.body.table
        count = req.body.count
        id = Number req.body.id
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

        # DataProvider.getData provider, table, count, onData
        dataHandler = new DataHandler
        dataHandler.getData provider, table, count, onData
    catch ex
        log.error V_(ex)
        throw ex

router.post "/db_config/get"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    provider = req.body.provider
    try
        DBConfig.getTables provider, (tableList) =>
            res.json tableList
    catch ex
        log.error V_(ex)
        throw ex

router.post "/db_config/add"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    table = req.body.table
    provider = req.body.provider
    action = req.body.action

    try
        metadataHandler = new MetadataHandler()
        metadataHandler.getTableMetadata provider, table, (metaData) ->
            DBConfig.addTable provider, metaData, action, (err) ->
                if not err?
                    res.status(200).send()
                else
                    res.status(500).send()
            return
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

        ConfigService.sendConfig component, config
        metadataHandler = new MetadataHandler
        metadataHandler.emptyProviderConfig component
        if not res.headersSent
            res.status(200).send()

    catch ex
        log.error V_(ex)
        throw ex

router.post "/get_diag"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) =>
    from = Number req.body.from
    levels = req.body.levels
    res.json DiagConnector.getRecords from, levels

router.use (err, req, res, next) =>
    log.error V_(req.url), V_(req.body), V_(err.message)
    res.status(if err.status? then err.status else 500).send(err.message)

module.exports = router
