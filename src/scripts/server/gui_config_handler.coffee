ConfigService = require "./config_sevice"
VirtDBConnector = require 'virtdb-connector'
log = VirtDBConnector.log
V_ = log.Variable

class GuiConfigHandler

    configTemplate: null
    currentConfig: null

    constructor: (@name) ->
        @initConfigTemplate()

    getConfig: () =>
        ConfigService.getConfig @name, @onConfig

    onConfig: (config) =>
        if not config.ConfigData? or config.ConfigData.length == 0
            @ConfigService.sendConfig VirtDBConnector.Convert.TemplateToOld @configTemplate
        else
            newFormatConfig = VirtDBConnector.Convert.TemplateToNew @config
            @currentConfig = VirtDBConnector.Convert.ToObject newFormatConfig

    initConfigTemplate: () =>
        configTemplate =
            AppName: @name
            Config: [
                VariableName: 'DatabaseConfigService'
                Type: 'STRING'
                Scope: '?'
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
