commandLineParameters = require("nomnom")
   .option('name', {
      abbr: 'n',
      help: 'Name of the component',
      required: false,
      default: "virtdb-gui"
   })
   .option('port', {
      abbr: 'p',
      default: 3000,
      help: 'the port where the server listen'
   })
   .option('service-config', {
      abbr: 's',
      default: "tcp://192.168.221.11:12345",
      help: 'the zmq address of the service config'
   })
   .option('timeout', {
      abbr: 't',
      default: "15000",
      help: 'request timeout'
   })
   .option('trace', {
      abbr: 'r',
      flag: true,
      default: "false",
      help: 'if set gui will display trace logs'
   })
   .parse();

ConfigService = require "./config_service"
util = require "util"
VirtDBConnector = (require "virtdb-connector")

class Configuration

    @DB_CONFIG_SERVICE = "DatabaseConfigService/ComponentName"
    @CACHE_TTL = "Cache/TTL"
    @CACHE_PERIOD = "Cache/CheckPeriod"
    @DEFAULTS = {}
    @DEFAULTS[@DB_CONFIG_SERVICE] = "greenplum-config"
    @DEFAULTS[@CACHE_TTL] = 600
    @DEFAULTS[@CACHE_PERIOD] = 60

    @_configListeners = {}
    @_parameters = {}

    @init: () =>
        ConfigService.subscribeToConfigs @onConfigReceived
        ConfigService.getConfig(commandLineParameters["name"], @onConfigReceived)

    @getCommandLineParameter: (parameter) =>
        if commandLineParameters[parameter]?
            return commandLineParameters[parameter]
        return null

    @getConfigServiceParameter: (parameterPath) =>
        if @_parameters[parameterPath]?
            return @_parameters[parameterPath]
        retrun null

    @addConfigListener: (parameterPath, listener) =>
        if not @_configListeners[parameterPath]?
            @_configListeners[parameterPath] = []
        @_configListeners[parameterPath].push listener
        value = @_parameters[parameterPath]
        if value?
            listener value
        else
            value = @DEFAULTS[parameterPath]
            if value?
                listener value

    @onConfigReceived: (configMsg) =>
        config = VirtDBConnector.Convert.ToObject VirtDBConnector.Convert.ToNew configMsg
        if Object.keys(config).length is 0
            #If there's no previously saved config in the config service
            ConfigService.sendConfigTemplate @_getConfigTemplate()
        else
            @_handleConfig config

    @_handleConfig: (config) =>
        #remove template
        delete config['']
        cfg = {}
        objProccess = (label, object) ->
            for key, val of object
                if label.length is 0
                    newKey = key
                else
                    newKey = label + "/" + key
                if typeof val is "object"
                    objProccess newKey, val
                else
                    cfg[newKey] = val
        objProccess "", config
        @_parameters = cfg
        @_notifyListeners()

    @_notifyListeners: =>
        for parameterPath, value of @_parameters
            listeners = @_configListeners[parameterPath]
            if listeners?
                for listener in listeners
                    listener value

    @_getConfigTemplate: () =>
         return configTemplate =
            AppName: @getCommandLineParameter "name"
            Config: [
                VariableName: 'ComponentName'
                Type: 'STRING'
                Scope: "DatabaseConfigService"
                Required: true
                Default: @DEFAULTS[@DB_CONFIG_SERVICE]
            ,
                VariableName: 'CheckPeriod'
                Type: 'UINT32'
                Required: true
                Scope: 'Cache'
                Default: @DEFAULTS[@CACHE_PERIOD]
            ,
                VariableName: 'TTL'
                Type: 'UINT32'
                Required: true
                Scope: 'Cache'
                Default: @DEFAULTS[@CACHE_TTL]
            ]

module.exports = Configuration
