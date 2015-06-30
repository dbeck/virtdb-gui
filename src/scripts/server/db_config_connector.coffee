zmq = require "zmq"
util = require "util"
Cache = require "./cache_handler"

VirtDB = require "virtdb-connector"
Config = require "./config"
Const = VirtDB.Const
log = VirtDB.log
V_ = log.Variable
Protocol = require "./protocol"

class DBConfig

    dbConfig = null
    DB_CONFIG_CACHE_PREFIX = "db_config_tables"

    @setDBConfig: (name) =>
        dbConfig = name
        emptyDBConfigCache()

    @getTables: (provider, onReady) =>
        try
            if (replyFromCache provider, onReady)
                return

            if not dbConfig?
                log.error "missing db config service"
                onReady []
                return

            message =
                Name: provider

            Protocol.sendDBConfigQuery dbConfig, message, (msg) ->
                try
                    if msg?.Tables?.length > 0
                        makeTableListResponse provider, msg.Tables, onReady
                    else
                        onReady []
                catch ex
                    log.error V_(ex)
                    throw ex
            return
        catch ex
            log.error V_(ex)
            throw ex

    @addTable: (provider, tableMeta, action, callback) =>
        if not dbConfig?
            log.error "missing db config service"
            return

        if not (checkMetadata tableMeta)
            return

        serverConfigMessage =
            Name: provider
            Table: tableMeta.Tables[0]
            Action: action

        Protocol.sendServerConfig dbConfig, serverConfigMessage, (err) ->
            if not err.Error?
                log.info "table added to the db config", V_(tableMeta.Name), V_(provider)
                err = null
            else
                log.error "table could not be added to db config", V_(err), V_(tableMeta.Name), V_(provider)
            Cache.delete cacheKey provider
            log.debug "db config cache were emptied", V_(tableMeta.Name), V_(provider)
            callback err

    emptyDBConfigCache = () =>
        keys = Cache.listKeys()
        for key in keys
            if key.indexOf(DB_CONFIG_CACHE_PREFIX) is 0
                Cache.delete key

    checkMetadata = (metadata) ->
        if not metadata?
            log.error "couldn't add table to the db config due to a problem with the meta data", V_(metadata)
            return false

        if metadata.Tables.length is not 1
            log.error "exactly one table should be in metadata", V_(metadata)
        return true

    makeTableListResponse = (provider, tables, callback) ->
        tableList = []
        for table in tables
            if not table.Schema? or table.Schema is ""
                tableList.push table.Name
            else
                tableList.push table.Schema + "." + table.Name
        if tableList.length > 0
            Cache.set (cacheKey provider), tableList
        callback tableList

    replyFromCache = (provider, onReady) ->
        tableList = Cache.get cacheKey provider
        if tableList? and util.isArray tableList
            log.trace "getting list of already added tables from cache.", V_(provider)
            onReady tableList
            return true
        return false

    cacheKey = (provider) ->
        return DB_CONFIG_CACHE_PREFIX + "_" + provider

Config.addConfigListener Config.DB_CONFIG_SERVICE, DBConfig.setDBConfig
module.exports = DBConfig
