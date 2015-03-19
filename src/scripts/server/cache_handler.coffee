NodeCache = require "node-cache"
Config = require "./config"
VirtDBConnector = require "virtdb-connector"
log = VirtDBConnector.log
V_ = log.Variable

class CacheHandler

    @_cache = null
    @_cacheTTL = null # seconds, 0 means unlimited
    @_keyExpirationListeners = {}

    @_reset: =>
        @_cache?._killCheckPeriod()
        @_cache = null
        @_cacheTTL = null

    @init: =>
        Config.addConfigListener Config.CACHE_TTL, CacheHandler._onNewCacheTTL

    @set: (key, value) =>
        if not @_cache?
            @_createCache()
        @_cache.set key, JSON.stringify value
        return

    @get: (key) =>
        if not @_cache?
            return null
        ret = (@_cache.get key)?[key]
        if ret?
            ret = JSON.parse ret
        return ret

    @delete: (key) =>
        if not @_cache?
            return
        @_cache.del key
        return

    @listKeys: =>
        if not @_cache?
            return []
        return @_cache.keys()

    @addKeyExpirationListener: (key, listener) =>
        @_keyExpirationListeners[key] ?= []
        @_keyExpirationListeners[key].push listener

    @_onNewCacheTTL: (ttl) =>
        @_cacheTTL = ttl
        @_createCache()

    @_createCache: =>
        options = {}
        options["checkperiod"] = Config.getCommandLineParameter "cacheCheckPeriod"
        if @_cacheTTL?
            options["stdTTL"] = @_cacheTTL
        @_cache = @_getCacheInstance options
        @_cache.on "expired", @_onKeyExpired
        return

    @_onKeyExpired: (key, value) =>
        log.debug key + " expired", V_(key)
        if @_keyExpirationListeners[key]?
            for callback in @_keyExpirationListeners[key]
                callback key
            delete @_keyExpirationListeners[key]

    @_getCacheInstance: (options) =>
        return new NodeCache(options)

module.exports = CacheHandler
