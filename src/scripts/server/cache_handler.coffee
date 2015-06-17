NodeCache = require "node-cache"
Config = require "./config"
VirtDBConnector = require "virtdb-connector"
log = VirtDBConnector.log
V_ = log.Variable

class CacheHandler

    cache = null
    ttl = 0 # seconds, 0 means unlimited
    keyExpirationListeners = {}

    @reset: =>
        cache?._killCheckPeriod()
        cache = null

    @init: =>
        Config.addConfigListener Config.CACHE_TTL, CacheHandler._onNewCacheTTL

    @set: (key, value) =>
        if not cache?
            createCache ttl
        cache.set key, JSON.stringify value
        return

    @get: (key) =>
        if not cache?
            return null
        ret = (cache.get key)?[key]
        if ret?
            ret = JSON.parse ret
        return ret

    @delete: (key) =>
        if not cache?
            return
        cache.del key
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
        if keyExpirationListeners[key]?
            listeners = keyExpirationListeners[key]
            delete keyExpirationListeners[key]
            for callback in listeners
                callback key

module.exports = CacheHandler
