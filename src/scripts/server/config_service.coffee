require("source-map-support").install()
VirtDBConnector = (require "virtdb-connector")
ConfigServiceConnector = require "./config_service_connection"
KeyValue = require "./key_value"
log = VirtDBConnector.log
V_ = log.Variable
Proto = require "virtdb-proto"
serviceConfigProto = Proto.service_config

class ConfigService

    @_addresses = null
    @_subscriptionListeners = []
    @_savedConfigs = {}
    @_configCallbacks = {}

    @_reset: () =>
        @_addresses = null
        @_subscriptionListeners = []
        @_savedConfigs = {}
        @_configCallbacks = {}

    @setAddresses: (addresses) =>
        @_addresses = addresses

    @getConfig: (component, onConfig) =>
        connection = ConfigServiceConnector.createInstance @_addresses[0]
        @_configCallbacks[component] = onConfig
        connection.getConfig component, (config) =>
            processedConfig = @_processGetConfigMessage config
            callback =  @_configCallbacks?[config.Name]
            if callback?
                @_savedConfigs[config.Name] = processedConfig
                callback processedConfig
                delete @_configCallbacks[config.Name]

    @sendConfig: (component, config) =>
        connection = ConfigServiceConnector.createInstance @_addresses[0]
        saved = ConfigService._savedConfigs?[component]
        if not saved? or (JSON.stringify(saved) isnt JSON.stringify(config))
            rawConfig = @_processSetConfigMessage component, config
            connection.sendConfig rawConfig

    @sendConfigTemplate: (template) =>
        log.debug "sending config template to the config service:", V_(template)
        connection = ConfigServiceConnector.createInstance @_addresses[0]
        connection.sendConfig VirtDBConnector.Convert.TemplateToOld template

    @onPublishedConfig: (channelId, message) =>
        config = serviceConfigProto.parse message, "virtdb.interface.pb.Config"
        procMsg = @_processGetConfigMessage config
        for callback in @_subscriptionListeners
            callback procMsg

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

module.exports = ConfigService
