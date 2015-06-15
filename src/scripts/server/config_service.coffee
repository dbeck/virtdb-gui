require("source-map-support").install()
VirtDB = (require "virtdb-connector")
ConfigServiceConnector = require "./config_service_connection"
KeyValue = require "./key_value"
log = VirtDB.log
Const = VirtDB.Const
V_ = log.Variable
Proto = require "virtdb-proto"
serviceConfigProto = Proto.service_config
Endpoints = require "./endpoints"

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

    @getConfig: (component, onConfig) =>
        connection = ConfigServiceConnector.createInstance Endpoints.getConfigServiceAddress()
        @_configCallbacks[component] = onConfig
        connection.getConfig component, (config) =>
            connection.close()
            processedConfig = @_processGetConfigMessage config
            callback =  @_configCallbacks?[config.Name]
            if callback?
                @_savedConfigs[config.Name] = processedConfig
                callback processedConfig
                delete @_configCallbacks[config.Name]

    isValid = (config) ->
        for item in config when item?.Data?
            data = item.Data
            if data.Value?.Value?[0]?
                value = data.Value.Value[0]
            if data.Minimum?.Value?[0]?
                minimum = data.Minimum.Value[0]
            if data.Maximum?.Value?[0]?
                maximum = data.Maximum.Value[0]
            required = data.Required?.Value
            if required and (not value? or value == '')
                return false
            if minimum? and ((not value? or value == '') or minimum > value)
                return false
            if maximum? and ((not value? or value == '') or maximum < value)
                return false
        return true

    @sendConfig: (component, config) =>
        if not isValid config
            return false
        connection = ConfigServiceConnector.createInstance Endpoints.getConfigServiceAddress()
        saved = ConfigService._savedConfigs?[component]
        if not saved? or (JSON.stringify(saved) isnt JSON.stringify(config))
            rawConfig = @_processSetConfigMessage component, config
            connection.sendConfig rawConfig
        connection.close()
        return true

    @sendConfigTemplate: (template) =>
        log.debug "sending config template to the config service:", V_(template)
        connection = ConfigServiceConnector.createInstance Endpoints.getConfigServiceAddress()
        connection.sendConfig VirtDB.Convert.TemplateToOld template
        connection.close()

    @onPublishedConfig: (channelId, message) =>
        try
            config = serviceConfigProto.parse message, "virtdb.interface.pb.Config"
        catch ex
            VirtDB.MonitoringService.requestError Const.CONFIG_SERVICE, Const.REQUEST_ERROR.INVALID_REQUEST, ex.toString()
            throw ex
        procMsg = @_processGetConfigMessage config
        for callback in @_subscriptionListeners
            callback procMsg

    @subscribeToConfigs: (listener) =>
        @_subscriptionListeners.push listener

    @_processGetConfigMessage: (config) =>
        newObject = VirtDB.Convert.ToObject VirtDB.Convert.ToNew config
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
