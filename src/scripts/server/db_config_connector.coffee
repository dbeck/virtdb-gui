require("source-map-support").install()
zmq = require "zmq"
fs = require "fs"
Proto = require "virtdb-proto"
NodeCache = require "node-cache"
ms = require "ms"
util = require "util"
Endpoints = require "./endpoints"

VirtDB = require "virtdb-connector"
Config = require "./config"
Const = VirtDB.Const
log = VirtDB.log
V_ = log.Variable

dbConfigProto = Proto.db_config

class DBConfig

    @_dbConfigService = null
    @_cacheTTL = null
    @_cacheCheckPeriod = null
    @_configuredTablesCache = null

    @_onNewDbConfService: (name) =>
        @_dbConfigService = name
        @_initCache()

    @_onNewCacheTTL: (ttl) =>
        @_cacheTTL = ttl
        @_initCache()

    @_onNewCacheCheckPeriod: (checkPeriod) =>
        @_cacheCheckPeriod = checkPeriod
        @_initCache()

    @_initCache: =>
        options = {}
        if @_cacheCheckPeriod?
            options["checkperiod"] = @_cacheCheckPeriod
        if @_cacheTTL?
            options["stdTTL"] = @_cacheTTL
        @_configuredTablesCache = new NodeCache(options)
        @_configuredTablesCache.on "expired", (key, value) =>
            log.debug "db config cache expired", V_(key)


    @addTable: (provider, tableMeta, action, callback) =>
        try
            if not tableMeta?
                log.error "couldn't add table to the db config due to a problem with the meta data", V_(tableMeta)
                return

            if tableMeta.Tables.length is not 1
                log.error "exactly one table should be in metadata", V_(tableMeta)

            if not @_dbConfigService?
                log.error "missing db config service"
                return

            tableMeta.Table = tableMeta.Tables[0]

            connection = DBConfigConnection.getConnection(@_dbConfigService)
            if not connection?
                log.error "unable to get db config connection"
                return

            connection.sendServerConfig provider, tableMeta, action, (err) =>
                if not err? or err isnt {}
                    log.info "table added to the db config", V_(tableMeta.Name), V_(provider)
                    err = null
                else
                    log.error "table could not be added to db config", V_(err), V_(tableMeta.Name), V_(provider)
                @_configuredTablesCache.del(provider)
                log.debug "db config cache were emptied", V_(tableMeta.Name), V_(provider)
                callback err
        catch ex
            log.error V_(ex)
            throw ex

    @getTables: (provider, onReady) =>
        try
            tableList = @_configuredTablesCache?.get(provider)[provider]
            if tableList? and util.isArray tableList
                log.trace "getting list of already added tables from cache.", V_(provider)
                onReady tableList
            else
                if not @_dbConfigService?
                    log.error "missing db config service"
                    onReady []
                    return
                log.debug "getting list of already added tables from db config.", V_(provider)
                connection = DBConfigConnection.getConnection(@_dbConfigService)
                if not connection?
                    log.error "unable to get db config connection"
                    onReady []
                    return
                connection.getTables provider, (msg) =>
                        try
                            if msg?.Tables?.length > 0
                                tableList = []
                                for table in msg.Tables
                                    if not table.Schema? or table.Schema is ""
                                        tableList.push table.Name
                                    else
                                        tableList.push table.Schema + "." + table.Name
                                if tableList.length > 0
                                    if not @_configuredTablesCache?
                                        @_initCache()
                                    @_configuredTablesCache.set(provider, tableList)
                                onReady tableList
                            else
                                onReady []
                        catch ex
                            log.error V_(ex)
                            throw ex
            return
        catch ex
            log.error V_(ex)
            throw ex

module.exports = DBConfig

class DBConfigConnection

    @getConnection: (service) ->
        return new DBConfigConnection(service)

    constructor: (@service) ->

    sendServerConfig: (provider, tableMeta, action, callback) =>
        tableMeta.Schema ?= ""
        serverConfigMessage =
            Name: provider
            Table: tableMeta.Table
            Action: action

        serializedMessage = dbConfigProto.serialize serverConfigMessage, "virtdb.interface.pb.ServerConfig"
        VirtDB.sendRequest @service, Const.ENDPOINT_TYPE.DB_CONFIG, serializedMessage, (err, message) =>
            try
                reply = dbConfigProto.parse message, "virtdb.interface.pb.ServerConfigReply"
            catch ex
                VirtDB.MonitoringService.requestError @service, Const.REQUEST_ERROR.INVALID_REQUEST, ex.toString()
            callback reply

    getTables: (provider, onReady) =>
        dbConfigQueryMessage = Name: provider
        serializedQuery = dbConfigProto.serialize dbConfigQueryMessage, "virtdb.interface.pb.DbConfigQuery"
        VirtDB.sendRequest @service, Const.ENDPOINT_TYPE.DB_CONFIG_QUERY, serializedQuery, (err, message) =>
            try
                confMsg = dbConfigProto.parse message, "virtdb.interface.pb.DbConfigReply"
            catch ex
                VirtDB.MonitoringService.requestError @service, Const.REQUEST_ERROR.INVALID_REQUEST, ex.toString()
            onReady confMsg

Config.addConfigListener Config.CACHE_TTL, DBConfig._onNewCacheTTL
Config.addConfigListener Config.DB_CONFIG_SERVICE, DBConfig._onNewDbConfService
