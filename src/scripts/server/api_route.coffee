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

log.setLevel "debug"
require('source-map-support').install()

# GET home page.
router.get "/", (req, res) ->
    res.json "{message: virtdb api}"
    return

router.get "/endpoints", (req, res) ->
    serviceConfig = EndpointService.getInstance()
    try
        res.json serviceConfig.getEndpoints()
    catch ex
        log.error ex
        res.status(500).send "Error occured: " + ex

router.get "/data_provider/:provider/meta_data/table/:table", (req, res) ->
    provider = req.params.provider
    table = req.params.table

    try
        DataProvider.getTableMeta provider, table, (metaData) ->
            res.json metaData
            return
    catch ex
        log.error ex
        res.status(500).send "Error occured: " + ex
        return

router.get "/data_provider/:provider/meta_data/table_names/from/:from/to/:to", (req, res) ->
    provider = req.params.provider
    from = Number(req.params.from)
    to = Number(req.params.to)

    try
        DataProvider.getTableNames provider, from, to, (tableNames) ->
            res.json tableNames
            return
    catch ex
        log.error ex
        res.status(500).send "Error occured: " + ex
        return

router.get "/data_provider/:provider/meta_data/table_names/search/:search", (req, res) ->
    provider = req.params.provider
    search = req.params.search

    try
        DataProvider.searchTableNames provider, search, (tableNames) ->
            res.json tableNames
            return
    catch ex
        log.error ex
        res.status(500).send "Error occured: " + ex
        return

router.get "/data_provider/:provider/data/table/:table/count/:count", (req, res) ->
    provider = req.params.provider
    table = req.params.table
    count = req.params.count

    try
        DataProvider.getData provider, table, count, (data) =>
            res.json data
    catch ex
        log.error ex
        res.status(500).send "Error occured: " + ex
        return

router.post "/db_config", (req, res) ->
    log.debug req.body
    table = req.body.table
    provider = req.body.provider
    tableMeta = null

    try
        DataProvider.getTableMeta provider, table, (metaData) ->
            DBConfig.addTable(provider, metaData)
            res.status(200).send()
            return
    catch ex
        log.error ex
        res.status(500).send "Error occured: " + ex
        return

router.post "/set_app_config", (req, res) ->
    log.debug "Set config"
    for key, value of req.body
        Config.Values[key] = value
    VirtDBLoader.start()
    return

router.get "/get_app_config", (req, res) ->
    log.debug "Get config"
    res.json Config.Values
    return

router.get "/get_config/:component", (req, res) =>
    try
        component = req.params.component
        log.debug "Getting config:", component
        ConfigService.getConfig component, (config) =>
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
        res.status(500).send "Error occured: " + ex
        return

router.post "/set_config/:component", (req, res) =>
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
        res.status(200).send()

    catch ex
        log.error ex
        res.status(500).send "Error occured: " + ex
        return

module.exports = router
