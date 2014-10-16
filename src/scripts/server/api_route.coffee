express = require "express"
router = express.Router()
log = require "loglevel"
util = require "util"
DataProvider = require "./data_provider_connector"
DBConfig = require "./db_config_connector"
Config = require "./config"
VirtDBLoader = require "./virtdb_loader"
KeyValue = require "./key_value"
ConfigService = require "./config_service"
EndpointService = require "./endpoint_service"

log.setLevel "debug"
require('source-map-support').install()

SCHEMA = ""

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
        DataProvider.getTableMeta provider, SCHEMA, table, (metaData) ->
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
        DataProvider.getTableNames provider, SCHEMA, from, to, (tableNames) ->
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
        DataProvider.searchTableNames provider, SCHEMA, search, (tableNames) ->
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
        DataProvider.getData provider, SCHEMA, table, count, (data) =>
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
        DataProvider.getTableMeta provider, SCHEMA, table, (metaData) ->
            DBConfig.addTable(provider, metaData)
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
                for scope in config.ConfigData
                    if scope.Key is ""
                        template = (KeyValue.toJSON scope)[""]
                        log.debug "template", template
                        res.json template
                # for scope in config.ConfigData
                #     if scope.Key isnt ""
                #         filledConfig = (KeyValue.toJSON scope)[scope.Key]
                #         for property, setting of filledConfig
                #             if setting.Value.length isnt 0
                #                 template[property][Value].push setting.Value[0]

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
        log.debug "Setting config:", component, config

        scopedConfig = {}
        scopedConfig[""] = config
        for property, configObj of config
            scope = configObj.Scope.Value[0]
            scopedConfig[scope] ?= {}
            scopedConfig[scope][property] ?= JSON.parse(JSON.stringify(configObj.Value))
            configObj.Value.Value = []

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
