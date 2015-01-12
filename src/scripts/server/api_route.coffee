express = require "express"
router = express.Router()
util = require "util"
DataProvider = require "./data_provider_connector"
DBConfig = require "./db_config_connector"
Config = require "./config"
VirtDBConnector = require "virtdb-connector"
VirtDBLoader = require "./virtdb_loader"
KeyValue = require "./key_value"
ConfigService = require "./config_service"
EndpointService = require "./endpoint_service"
DiagConnector = require "./diag_connector"
timeout = require "connect-timeout"
ok = require "okay"
log = VirtDBConnector.log
V_ = log.Variable

DataHandler = require "./data_handler"
MetadataHandler = require "./meta_data_handler"

require('source-map-support').install()

router.use require 'express-domain-middleware'

# GET home page.
router.get "/", timeout(Config.getCommandLineParameter("timeout")), (req, res, next) ->
    res.json "{message: virtdb api}"
    return

router.get "/endpoints", timeout(Config.getCommandLineParameter("timeout")), (req, res, next) ->
    serviceConfig = EndpointService.getInstance()
    try
        if not res.headersSent
            res.json serviceConfig.getEndpoints()
    catch ex
        log.error V_(ex)
        throw ex

router.post "/data_provider/meta_data/", timeout(Config.getCommandLineParameter("timeout")), (req, res, next) ->
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
        # DataProvider.getTableMeta provider, table,
        metadataHandler = new MetadataHandler()
        metadataHandler.getTableMetadata provider, table, onMetadata
    catch ex
        log.error V_(ex)
        throw ex

router.post "/data_provider/table_list", timeout(Config.getCommandLineParameter("timeout")), (req, res, next) =>
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

router.post "/data_provider/data", timeout(Config.getCommandLineParameter("timeout")), (req, res, next) ->
    try
        provider = req.body.provider
        table = req.body.table
        count = req.body.count
        id = Number req.body.id
        onData = (data) ->
            if not res.headersSent
                response =
                    data: data
                    id: id
                res.json response
        # DataProvider.getData provider, table, count, onData
        dataHandler = new DataHandler
        dataHandler.getData provider, table, count, onData
    catch ex
        log.error V_(ex)
        throw ex

router.post "/db_config/get", timeout(Config.getCommandLineParameter("timeout")), (req, res, next) ->
    provider = req.body.provider
    try
        DBConfig.getTables provider, (tableList) =>
            res.json tableList
    catch ex
        log.error V_(ex)
        throw ex

router.post "/db_config/add", timeout(Config.getCommandLineParameter("timeout")), (req, res, next) ->
    table = req.body.table
    provider = req.body.provider

    try
        DataProvider.getTableMeta provider, table, (metaData) ->
            DBConfig.addTable(provider, metaData)
            res.status(200).send()
            return
    catch ex
        log.error V_(ex)
        throw ex

router.get "/get_config/:component", timeout(Config.getCommandLineParameter("timeout")), (req, res, next) =>
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

router.post "/set_config/:component", timeout(Config.getCommandLineParameter("timeout")), (req, res, next) =>
    try
        component = req.params.component
        config = req.body

        ConfigService.sendConfig component, config
        if not res.headersSent
            res.status(200).send()

    catch ex
        log.error V_(ex)
        throw ex

router.post "/get_diag", timeout(Config.getCommandLineParameter("timeout")), (req, res, next) =>
    from = Number req.body.from
    levels = req.body.levels
    res.json DiagConnector.getRecords from, levels

router.use (err, req, res, next) =>
    log.error V_(req.url), V_(req.body), V_(err)
    res.status(if err.status? then err.status else 500).send(err.message)

module.exports = router
