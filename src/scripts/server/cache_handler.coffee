NodeCache = require "node-cache"
Config = require "./config"
VirtDB = require "virtdb-connector"
log = VirtDB.log
V_ = log.Variable

class CacheHandler

    cache = null
    ttl = 0 # seconds, 0 means unlimited
    keyExpirationListeners = {}
    DB_CONFIG_CACHE_PREFIX = "DBCONFIG$$$"
    METADATA_CACHE_PREFIX = "METADATA$$$"

    @reset: =>
        cache?._killCheckPeriod()
        cache = null

    @init: =>
        Config.addConfigListener Config.CACHE_TTL, CacheHandler._onNewCacheTTL

    @set: (key, value) =>
        if not cache?
            createCache ttl
        cache.set key, JSON.stringify value
        VirtDB.MonitoringService.bumpStatistic "Cache set"
        return

    @get: (key) =>
        if not cache?
            return null
        ret = (cache.get key)?[key]
        if ret?
            ret = JSON.parse ret
        VirtDB.MonitoringService.bumpStatistic "Cache get"
        return ret

    @delete: (key) =>
        if not cache?
            return
        cache.del key
        VirtDB.MonitoringService.bumpStatistic "Cache delete"
        return

    @listKeys: =>
        if not cache?
            return []
        return cache.keys()

    @addKeyExpirationListener: (key, listener) =>
        keyExpirationListeners[key] ?= []
        keyExpirationListeners[key].push listener

    @_onNewCacheTTL: (newTTL) =>
        ttl = newTTL
        createCache ttl

    @generateDBConfigCacheKey: (provider) ->
        DB_CONFIG_CACHE_PREFIX + provider

    @generateCacheKeyForMetadata: (provider, request) ->
        METADATA_CACHE_PREFIX + provider + "_" + JSON.stringify request

    @parseCacheKeyOfMetadata: (key) ->
        if key.indexOf(METADATA_CACHE_PREFIX) is 0
            keyWithoutPrefix = key.substring METADATA_CACHE_PREFIX.length
            separatorIndex = keyWithoutPrefix.indexOf('_')
            provider = keyWithoutPrefix.substring 0, separatorIndex
            request = keyWithoutPrefix.substring separatorIndex + 1
            [provider, (JSON.parse request)]
        else
            null

    @emptyDBConfig: () =>
        keys = @listKeys()
        for key in keys
            if key.indexOf(DB_CONFIG_CACHE_PREFIX) is 0
                @delete key

    createCache = (ttl) ->
        options = {}
        options["checkperiod"] = Config.getCommandLineParameter "cacheCheckPeriod"
        if ttl?
            options["stdTTL"] = ttl
        cache = new NodeCache options
        cache.on "expired", onKeyExpired
        return

    onKeyExpired = (key, value) ->
        log.debug key + " expired", V_(key)
        VirtDB.MonitoringService.bumpStatistic "Cache key expired"
        if keyExpirationListeners[key]?
            listeners = keyExpirationListeners[key]
            delete keyExpirationListeners[key]
            for callback in listeners
                callback key

module.exports = CacheHandler
