express = require "express"
router = express.Router()
log = require "loglevel"

DataProvider = require "./data_provider_connector"
DBConfig = require "./db_config_connector"
Config = require "./config"

VirtDBLoader = require "./virtdb_loader"

KeyValue = (require "virtdb-connector").KeyValue
ConfigService = (require "virtdb-connector").ConfigService
EndpointService = (require "virtdb-connector").EndpointService

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

router.post "/set_config", (req, res) ->
    log.debug "Set config"
    for key, value of req.body
        Config.Values[key] = value
    VirtDBLoader.start()
    EndpointService.setConnectionData(Config.Values.CONFIG_SERVICE_NAME, Config.Values.CONFIG_SERVICE_ADDRESS)
    EndpointService.getInstance()
    return

router.get "/get_config", (req, res) ->
    log.debug "Get config"
    res.json Config.Values
    return

router.get "/configs", (req, res) =>
    log.debug "Configs"
    configs = ConfigService.getInstance().getConfigs()
    log.debug configs
    res.json KeyValue.toJSON(configs["sap_data_provider"].ConfigData[0])

module.exports = router
