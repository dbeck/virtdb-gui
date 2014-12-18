NodeCache = require "node-cache"
Config = require "./config"

class CacheHandler

    @_cache = null
    @_cacheTTL = null
    @_cacheCheckPeriod = null

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
        @resetCache()

    @_onNewCacheCheckPeriod: (checkPeriod) =>
        @_cacheCheckPeriod = checkPeriod
        @resetCache()

    @_createCache: =>
        options = {}
        if @_cacheCheckPeriod?
            options["checkperiod"] = @_cacheCheckPeriod
        if @_cacheTTL?
            options["stdTTL"] = @_cacheTTL
        @_cache = new NodeCache(options)
        @_cache.on "expired", (key, value) =>
            log.debug key + " expired", V_(key)

Config.addConfigListener Config.CACHE_PERIOD, CacheHandler._onNewCacheCheckPeriod
Config.addConfigListener Config.CACHE_TTL, CacheHandler._onNewCacheTTL

module.exports = CacheHandler
