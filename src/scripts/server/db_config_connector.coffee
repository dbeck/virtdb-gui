require("source-map-support").install()
zmq = require "zmq"
fs = require "fs"
Proto = require "virtdb-proto"
NodeCache = require "node-cache"
ms = require "ms"
util = require "util"
Endpoints = require "./endpoints"

VirtDBConnector = require "virtdb-connector"
Config = require "./config"
Const = VirtDBConnector.Const
log = VirtDBConnector.log
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
            tableList = @_configuredTablesCache.get(provider)[provider]
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
        serverConfigAddress = Endpoints.getDbConfigAddress service
        dbConfigQueryAddress = Endpoints.getDbConfigQueryAddress service

        if not serverConfigAddress? or serverConfigAddress?.length is 0
            log.error "cannot find db_config server config addresses"
            return null
        if not dbConfigQueryAddress? or dbConfigQueryAddress?.length is 0
            log.error "cannot find db_config query addresses"
            return null
        return new DBConfigConnection(serverConfigAddress, dbConfigQueryAddress)

    _pushPullSocket: null
    _reqRepSocket: null

    constructor: (@serverConfigAddress, @dbConfigQueryAddress) ->

    sendServerConfig: (provider, tableMeta, action, callback) =>

        @_pushPullSocket = zmq.socket(Const.ZMQ_REQ)
        @_pushPullSocket.on "message", (msg) =>
            reply = dbConfigProto.parse msg, "virtdb.interface.pb.ServerConfigReply"
            callback reply

        for addr in @serverConfigAddress
            @_pushPullSocket.connect addr

        tableMeta.Schema ?= ""
        serverConfigMessage =
            Name: provider
            Table: tableMeta.Table
            Action: action
        @_pushPullSocket.send dbConfigProto.serialize serverConfigMessage, "virtdb.interface.pb.ServerConfig"

    getTables: (provider, onReady) =>
        dbConfigQueryMessage = Name: provider
        @_reqRepSocket = zmq.socket(Const.ZMQ_REQ)
        for addr in @dbConfigQueryAddress
            @_reqRepSocket.connect addr
        @_reqRepSocket.on "message", (msg) =>
            try
                confMsg = dbConfigProto.parse msg, "virtdb.interface.pb.DbConfigReply"
                onReady confMsg
            catch ex
                log.error V_(ex)
                throw ex
        @_reqRepSocket.send dbConfigProto.serialize dbConfigQueryMessage, "virtdb.interface.pb.DbConfigQuery"

Config.addConfigListener Config.CACHE_PERIOD, DBConfig._onNewCacheCheckPeriod
Config.addConfigListener Config.CACHE_TTL, DBConfig._onNewCacheTTL
Config.addConfigListener Config.DB_CONFIG_SERVICE, DBConfig._onNewDbConfService
