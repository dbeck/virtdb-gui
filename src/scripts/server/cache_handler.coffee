NodeCache = require "node-cache"
Config = require "./config"
VirtDBConnector = require "virtdb-connector"
log = VirtDBConnector.log
V_ = log.Variable

class CacheHandler

    @_cache = null
    @_cacheTTL = null
    @_cacheCheckPeriod = null

    @init: =>
        Config.addConfigListener Config.CACHE_PERIOD, CacheHandler._onNewCacheCheckPeriod
        Config.addConfigListener Config.CACHE_TTL, CacheHandler._onNewCacheTTL

    @set: (key, value) =>
        if not @_cache?
            @_createCache()
        @_cache.set key, value
        return

    @get: (key) =>
        if not @_cache?
            return null
        return @_cache.get key

    @_onNewCacheTTL: (ttl) =>
        @_cacheTTL = ttl
        @_createCache()

    @_onNewCacheCheckPeriod: (checkPeriod) =>
        @_cacheCheckPeriod = checkPeriod
        @_createCache()

    @_createCache: =>
        options = {}
        if @_cacheCheckPeriod?
            options["checkperiod"] = @_cacheCheckPeriod
        if @_cacheTTL?
            options["stdTTL"] = @_cacheTTL
        @_cache = new NodeCache(options)
        @_cache.on "expired", (key, value) =>
            log.debug key + " expired", V_(key)

module.exports = CacheHandler
