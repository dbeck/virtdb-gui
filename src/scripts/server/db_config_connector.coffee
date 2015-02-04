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
Const = VirtDBConnector.Constants
log = VirtDBConnector.log
V_ = log.Variable
FieldData = require "./fieldData"

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


    @addTable: (provider, tableMeta) =>
        try
            if not tableMeta?
                log.error "couldn't add table to the db config due to a problem with the meta data", V_(tableMeta)
                return

            connection = DBConfigConnection.getConnection(@_dbConfigService)
            connection.sendServerConfig provider, tableMeta
            log.info "table added to the db config", V_(tableMeta.Name), V_(provider)
            @_configuredTablesCache.del(provider)
            log.debug "db config cache were emptied", V_(tableMeta.Name), V_(provider)
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
                log.debug "getting list of already added tables from db config.", V_(provider)
                connection = DBConfigConnection.getConnection(@_dbConfigService)
                connection.getTables provider, (msg) =>
                        try
                            if msg.Servers.length > 0
                                if msg?.Servers[0]?.Tables?
                                    tableList = []
                                    for table in msg.Servers[0].Tables
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
        return new DBConfigConnection(serverConfigAddress, dbConfigQueryAddress)

    _pushPullSocket: null
    _reqRepSocket: null

    constructor: (@serverConfigAddress, @dbConfigQueryAddress) ->

    sendServerConfig: (provider, tableMeta) =>

        @_pushPullSocket = zmq.socket(Const.ZMQ_PUSH)
        for addr in @serverConfigAddress
            @_pushPullSocket.connect addr

        tableMeta.Schema ?= ""
        serverConfigMessage =
            Type: Const.SERVER_CONFIG_TYPE
            Name: provider
            Tables: [tableMeta]
        console.log "socket send:", @serverConfigAddress
        console.dir serverConfigMessage
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
