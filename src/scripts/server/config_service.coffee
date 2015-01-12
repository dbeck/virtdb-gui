zmq = require "zmq"
fs = require "fs"
util = require "util"
VirtDBConnector = (require "virtdb-connector")
Proto = require "virtdb-proto"
Const = VirtDBConnector.Constants
log = VirtDBConnector.log
V_ = log.Variable
KeyValue = require "./key_value"

require("source-map-support").install()
log.setLevel "debug"

serviceConfigProto = Proto.service_config

class ConfigService

    @_address: null
    @_subscriptionListeners = []
    @_savedConfigs = {}
    @_configCallbacks = {}

    @setAddress: (address) ->
        @_address = address

    @getConfig: (component, onConfig) =>
        connection = new ConfigServiceConnector(@_address)
        @_configCallbacks[component] = onConfig
        connection.getConfig component, (config) ->
            processedConfig = ConfigService._processGetConfigMessage config
            callback =  ConfigService?._configCallbacks?[config.Name]
            if callback?
                ConfigService._savedConfigs[config.Name] = processedConfig
                callback processedConfig
                delete ConfigService._configCallbacks[config.Name]

    @sendConfig: (component, config) =>
        connection = new ConfigServiceConnector(@_address)
        saved = ConfigService._savedConfigs?[component]
        if saved? and (JSON.stringify(saved) isnt JSON.stringify(config))
            rawConfig =  @_processSetConfigMessage component, config
            connection.sendConfig rawConfig

    @sendConfigTemplate: (template) =>
        log.debug "sending config template to the config service:", V_(template)
        @sendConfig VirtDBConnector.Convert.TemplateToOld template

    @onPublishedConfig: (appName, message) =>
        config = serviceConfigProto.parse message, "virtdb.interface.pb.Config"
        for callback in @_subscriptionListeners
            callback config

    @subscribeToConfigs: (listener) =>
        @_subscriptionListeners.push listener

    @_processGetConfigMessage: (config) =>
        newObject = VirtDBConnector.Convert.ToObject VirtDBConnector.Convert.ToNew config
        for scope in config.ConfigData
            if scope.Key is ""
                resultArray = []
                for child in scope.Children
                    item =
                        Name: child.Key
                        Data: {}
                    for variable in child.Children
                        convertedVariable = KeyValue.toJSON variable
                        item.Data[variable.Key] = convertedVariable[variable.Key]
                    resultArray.push item
                convertedTemplate = (KeyValue.toJSON scope)[""]
                for item in resultArray
                    value = newObject[item.Data.Scope.Value[0]]?[item.Name]
                    value = null unless value?
                    item.Data.Value.Value.push value
                return resultArray
        return null

    @_processSetConfigMessage: (component, config) =>
        scopedConfig = {}
        scopedConfig[""] = {}
        for item in config
            scopedConfig[""][item.Name] = item.Data
            scope = item.Data.Scope.Value[0]
            if item.Data.Value.Value[0]? and item.Data.Value.Value[0].length isnt 0
                scopedConfig[scope] ?= {}
                scopedConfig[scope][item.Name] ?= JSON.parse(JSON.stringify(item.Data.Value))
            item.Data.Value.Value = []

        configMessage =
            Name: component
            ConfigData: KeyValue.parseJSON(scopedConfig)
        return configMessage

    class ConfigServiceConnector

        _reqRepSocket: null
        _onConfig: null
        _address: null

        constructor: (@_address) ->
            @configs = {}
            @_reqRepSocket = zmq.socket(Const.ZMQ_REQ)
            @_reqRepSocket.on "message", @_onMessage
            @_connect()

        getConfig: (component, readyCallback) =>
            try
                @_onConfig = readyCallback
                configReq =
                    Name: component
                log.debug "sending config request message:", V_(configReq)
                @_reqRepSocket.send serviceConfigProto.serialize configReq, "virtdb.interface.pb.Config"
            catch ex
                log.error V_(ex)
                throw ex

        sendConfig: (config) =>
            try
                log.debug "sending config to the config service:", V_(config)
                @_reqRepSocket.send serviceConfigProto.serialize config, "virtdb.interface.pb.Config"
            catch ex
                log.error V_(ex)
                throw ex

        _onMessage: (message) =>
            try
                configMessage = serviceConfigProto.parse message, "virtdb.interface.pb.Config"
                log.debug "got config message: ", V_(configMessage)
                if @_onConfig?
                    @_onConfig configMessage
                return
            catch ex
                log.error V_(ex)
                throw ex

        _connect: =>
            try
                @_reqRepSocket.connect(@_address)
            catch ex
                log.error V_(ex)
                throw ex

module.exports = ConfigService
