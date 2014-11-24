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
commandLine = require("nomnom").parse()

require('source-map-support').install()

router.use require 'express-domain-middleware'

# GET home page.
router.get "/", timeout(commandLine.timeout), (req, res, next) ->
    res.json "{message: virtdb api}"
    return

router.get "/endpoints", timeout(commandLine.timeout), (req, res, next) ->
    serviceConfig = EndpointService.getInstance()
    try
        if not res.headersSent
            res.json serviceConfig.getEndpoints()
    catch ex
        log.error V_(ex)
        throw ex

router.post "/data_provider/meta_data/", timeout(commandLine.timeout), (req, res, next) ->
    provider = req.body.provider
    table = req.body.table
    id = Number req.body.id

    try
        DataProvider.getTableMeta provider, table, (metaData) ->
            log.debug "Try to send, response to meta data request:", metaData.Name
            if not res.headersSent
                metaDataResponse = JSON.parse JSON.stringify metaData
                for field in metaDataResponse.Fields
                    properties = {}
                    for prop in field.Properties
                        formattedProp = KeyValue.toJSON prop
                        for key, value of formattedProp
                            properties[key] = value
                    field.Properties = properties
                response =
                    data: metaDataResponse
                    id: id
                res.json response
    catch ex
        log.error V_(ex)
        throw ex

router.post "/data_provider/table_list", timeout(commandLine.timeout), (req, res, next) =>
    provider = req.body.provider
    from = Number req.body.from
    to = Number req.body.to
    search = req.body.search
    id = Number req.body.id
    tablesToFilter = req.body.tables
    try
        DataProvider.getTableNames provider, search, from, to, tablesToFilter, (result) ->
            if not res.headersSent
                response =
                    data: result
                    id: id
                res.json response
                return
    catch ex
        log.error V_(ex)
        throw ex

router.post "/data_provider/data", timeout(commandLine.timeout), (req, res, next) ->
    try
        provider = req.body.provider
        table = req.body.table
        count = req.body.count
        id = Number req.body.id
        DataProvider.getData provider, table, count, (data) =>
            if not res.headersSent
                response =
                    data: data
                    id: id
                res.json response
    catch ex
        log.error V_(ex)
        throw ex

router.post "/db_config/get", timeout(commandLine.timeout), (req, res, next) ->
    provider = req.body.provider
    try
        DBConfig.getTables provider, (tableList) =>
            res.json tableList
    catch ex
        log.error V_(ex)
        throw ex

router.post "/db_config/add", timeout(commandLine.timeout), (req, res, next) ->
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

router.post "/set_app_config", timeout(commandLine.timeout), (req, res) ->
    for key, value of req.body
        Config.Values[key] = value
    VirtDBLoader.start()
    res.status(200).send()
    return

router.get "/get_app_config", timeout(commandLine.timeout, {respond: true}), (req, res, next) ->
    res.json Config.Values
    return

router.get "/get_config/:component", timeout(commandLine.timeout), (req, res, next) =>
    try
        component = req.params.component
        ConfigService.getConfig component, (config) =>
            "Got response from the endpoint service."
            template = {}
            if config.ConfigData.length isnt 0
                newObject = VirtDBConnector.Convert.ToObject VirtDBConnector.Convert.ToNew config
                for scope in config.ConfigData
                    if scope.Key is ""
                        resultArray = []
                        for child in scope.Children
                            item =
                                Name: child.Key
                                Data: {}
                            for variable in child.Children
                                convertedVariable = KeyValue.toJSON variable
                                item.Data[variable.Key] = convertedVariable[variable.Key]
                            resultArray.push item
                        convertedTemplate = (KeyValue.toJSON scope)[""]
                        for item in resultArray
                            item.Data.Value.Value.push newObject[item.Data.Scope.Value[0]]?[item.Name]
                        res.json resultArray
            else
                res.json {}
    catch ex
        log.error V_(ex)
        throw ex

router.post "/set_config/:component", timeout(commandLine.timeout), (req, res, next) =>
    try
        component = req.params.component
        config = req.body

        scopedConfig = {}
        scopedConfig[""] = {}
        for item in config
            scopedConfig[""][item.Name] = item.Data
            scope = item.Data.Scope.Value[0]
            scopedConfig[scope] ?= {}
            scopedConfig[scope][item.Name] ?= JSON.parse(JSON.stringify(item.Data.Value))
            item.Data.Value.Value = []

        configMessage =
            Name: component
            ConfigData: KeyValue.parseJSON(scopedConfig)

        ConfigService.sendConfig configMessage
        if not res.headersSent
            res.status(200).send()

    catch ex
        log.error V_(ex)
        throw ex

router.post "/get_diag", timeout(commandLine.timeout), (req, res, next) =>
    from = Number req.body.from
    levels = req.body.levels
    res.json DiagConnector.getRecords from, levels

router.use (err, req, res, next) =>
    log.error V_(req.url), V_(req.body), V_(err)
    res.status(if err.status? then err.status else 500).send(err.message)

module.exports = router
