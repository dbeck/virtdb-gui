ConfigService = require "./config_service"
VirtDBConnector = require 'virtdb-connector'
log = VirtDBConnector.log
util = require "util"
V_ = log.Variable
protobuf = require "node-protobuf"
fs = require "fs"

serviceConfigProto = new protobuf(fs.readFileSync("common/proto/svc_config.pb.desc"))

class GuiConfigHandler

    _currentConfig: null
    _name: null

    constructor: () ->

    setName: (name) =>
        @_name = name
        return

    getConfig: () =>
        ConfigService.getConfig @_name, @onConfig

    onConfig: (config) =>
        if not config.ConfigData? or config.ConfigData.length is 0
            ConfigService.sendConfig VirtDBConnector.Convert.TemplateToOld @_getConfigTemplate()
        else
            @_setCurrentConfig config

    _setCurrentConfig: (cfg) =>
        newStyle = VirtDBConnector.Convert.ToNew cfg
        @_currentConfig = VirtDBConnector.Convert.ToObject newStyle

    onPublishedConfig: (appName, message) =>
        config = serviceConfigProto.parse message, "virtdb.interface.pb.Config"
        @_setCurrentConfig config

    _getConfigTemplate: () =>
         return configTemplate =
            AppName: @_name
            Config: [
                VariableName: 'ComponentName'
                Type: 'STRING'
                Scope: "DatabaseConfigService"
                Required: true
                Default: "greenplum-config"
            ,
                VariableName: 'CheckPeriod'
                Type: 'UINT32'
                Required: true
                Scope: 'Cache'
                Default: 60
            ,
                VariableName: 'TTL'
                Type: 'UINT32'
                Required: true
                Scope: 'Cache'
                Default: 600
            ]

guiConfigHandler = new GuiConfigHandler
module.exports = guiConfigHandler
