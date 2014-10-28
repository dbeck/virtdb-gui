express = require "express"
router = express.Router()
log = require "loglevel"
util = require "util"
DataProvider = require "./data_provider_connector"
DBConfig = require "./db_config_connector"
Config = require "./config"
VirtDBConnector = require "virtdb-connector"
VirtDBLoader = require "./virtdb_loader"
KeyValue = require "./key_value"
ConfigService = require "./config_service"
EndpointService = require "./endpoint_service"
timeout = require "connect-timeout"

log.setLevel "debug"
require('source-map-support').install()

onRequestTimeout = (res) =>
    res.status(503).send('Request timeout occurred')

# GET home page.
router.get "/", timeout(Config.Values.REQUEST_TIMEOUT, {respond: false}), (req, res) ->
    req.on "timeout", () =>
        onRequestTimeout(res)
    res.json "{message: virtdb api}"
    return

router.get "/endpoints", timeout(Config.Values.REQUEST_TIMEOUT, {respond: false}), (req, res) ->
    req.on "timeout", () =>
        onRequestTimeout(res)
    serviceConfig = EndpointService.getInstance()
    try
        if not res.headersSent
            res.json serviceConfig.getEndpoints()
    catch ex
        log.error ex
        res.status(500).send "Error occurred: " + ex

router.post "/data_provider/meta_data/", timeout(Config.Values.REQUEST_TIMEOUT, {respond: false}), (req, res) ->

    req.on "timeout", () =>
        onRequestTimeout(res)

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
        log.error ex
        res.status(500).send "Error occurred: " + ex
        return

router.post "/data_provider/table_list", timeout(Config.Values.REQUEST_TIMEOUT, {respond: false}), (req, res) =>

    req.on "timeout", () =>
        onRequestTimeout(res)

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
        log.error ex
        res.status(500).send "Error occurred: " + ex
        return

router.post "/data_provider/data", timeout(Config.Values.REQUEST_TIMEOUT, {respond: false}), (req, res) ->
    req.on "timeout", () =>
        onRequestTimeout(res)

    provider = req.body.provider
    table = req.body.table
    count = req.body.count
    id = Number req.body.id

    try
        DataProvider.getData provider, table, count, (data) =>
            if not res.headersSent
                response =
                    data: data
                    id: id
                res.json response
    catch ex
        log.error ex
        res.status(500).send "Error occurred: " + ex
        return

router.post "/db_config", timeout(Config.Values.REQUEST_TIMEOUT, {respond: false}), (req, res) ->
    req.on "timeout", () =>
        onRequestTimeout(res)

    table = req.body.table
    provider = req.body.provider

    try
        DataProvider.getTableMeta provider, table, (metaData) ->
            DBConfig.addTable(provider, metaData)
            res.status(200).send()
            return
    catch ex
        log.error ex
        res.status(500).send "Error occurred: " + ex
        return

router.post "/set_app_config", timeout(Config.Values.REQUEST_TIMEOUT, {respond: false}), (req, res) ->
    req.on "timeout", () =>
        onRequestTimeout(res)

    log.debug "Set config"
    for key, value of req.body
        Config.Values[key] = value
    VirtDBLoader.start()
    res.status(200).send()
    return

router.get "/get_app_config", timeout(Config.Values.REQUEST_TIMEOUT, {respond: false}), (req, res) ->
    req.on "timeout", () =>
        onRequestTimeout(res)
    log.debug "Get config"
    res.json Config.Values
    return

router.get "/get_config/:component", timeout(Config.Values.REQUEST_TIMEOUT, {respond: false}), (req, res) =>
    req.on "timeout", () =>
        onRequestTimeout(res)
    try
        component = req.params.component
        log.debug "Getting config:", component
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
        log.error ex
        res.status(500).send "Error occurred: " + ex
        return

router.post "/set_config/:component", timeout(Config.Values.REQUEST_TIMEOUT, {respond: false}), (req, res) =>
    req.on "timeout", () =>
        onRequestTimeout(res)
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
        log.error ex
        res.status(500).send "Error occurred: " + ex
        return

module.exports = router
