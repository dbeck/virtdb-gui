nomnom = require "nomnom"
path = require 'path'
CLI_OPTIONS =
    name:
        abbr: 'n',
        help: 'Name of the component'
        default: "virtdb-gui"
    port:
        abbr: 'p'
        default: 3000
        help: 'the port where the server listen'
    serviceConfig:
        full: "service-config"
        abbr: 's',
        default: "tcp://192.168.221.11:12345"
        help: 'the zmq address of the service config'
    timeout:
        abbr: 't'
        default: "15000"
        help: 'request timeout'
    trace:
        abbr: 'r'
        flag: true
        default: "false"
        help: 'if set gui will display trace logs'
    forceConsoleLog:
        abbr: 'c'
        flag: true
        full: "force-console-log"
        default: "false"
        help: 'if set gui will write log messages to the console'
    cacheCheckPeriod:
        abbr: 'r'
        full: "cache-check-period"
        default: 1
        help: 'the cache check period in seconds'
    logLevel:
        abbr: 'l'
        full: "log-level"
        default: "info"
        choices: ['trace', 'debug', 'info', 'warn', 'error']
        help: 'log level'
    authFile:
        abbr: 'a'
        full: "auth-file"
        default: "login.json"
        help: "JSON file containing array of user objects with username and password fields"

nomnom.options(CLI_OPTIONS).parse()

ConfigService = require "./config_service"
util = require "util"
VirtDBConnector = (require "virtdb-connector")

Features =
    Installer: false
    Security: false

class Configuration

    @Features = Features
    @DB_CONFIG_SERVICE = "DatabaseConfigService/ComponentName"
    @CACHE_TTL = "Cache/TTL"
    @CACHE_PERIOD = "Cache/CheckPeriod"
    @DEFAULTS = {}
    @DEFAULTS[@DB_CONFIG_SERVICE] = "greenplum-config"
    @DEFAULTS[@CACHE_TTL] = 600
    @DEFAULTS[@CACHE_PERIOD] = 60
    @Installed = false

    @_configListeners = {}
    @_parameters = {}
    @_commandLine = {}

    @reset: =>
        @_configListeners = {}
        @_parameters = {}
        @_commandLine = {}

    @init: () =>
        ConfigService.subscribeToConfigs @onConfigReceived
        ConfigService.getConfig @getCommandLineParameter("name"), @onConfigReceived

    @isInstalled: ->
        return @Installed

    @getCommandLineParameter: (parameter) =>
        if Object.keys(@_commandLine).length is 0
            @_parseCommandLine()
        if @_commandLine[parameter]?
            return @_commandLine[parameter]
        return null

    @getConfigServiceParameter: (parameterPath) =>
        if @_parameters[parameterPath]?
            return @_parameters[parameterPath]
        return null

    @projectRoot: ->
        path.dirname require.main.filename

    @addConfigListener: (parameterPath, listener) =>
        if not listener?
            return
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

    @onConfigReceived: (config) =>
        if not config?
            #If there's no previously saved config in the config service
            ConfigService.sendConfigTemplate @_getConfigTemplate()
        else
            @_handleConfig config

    @_handleConfig: (config) =>
        cfg = {}
        for cfgEntry in config
            if cfgEntry.Data.Scope.Value[0]?
                key = cfgEntry.Data.Scope.Value[0] + "/" + cfgEntry.Name
            else
                key = cfgEntry.Name
            cfg[key] = cfgEntry.Data.Value.Value[0]

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
                VariableName: 'TTL'
                Type: 'UINT32'
                Required: true
                Scope: 'Cache'
                Default: @DEFAULTS[@CACHE_TTL]
            ]

    @_parseCommandLine: (argv) =>
        if argv?
            @_commandLine = nomnom.options(CLI_OPTIONS).parse(argv)
        else
            @_commandLine = nomnom.options(CLI_OPTIONS).parse()

module.exports = Configuration
