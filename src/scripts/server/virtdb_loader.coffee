Configuration = require "./config"
ConfigService = require "./config_service"
Endpoints = require "./endpoints"
DiagConnector = require "./diag_connector"
CacheHandler = require "./cache_handler"
VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Constants

class VirtDBLoader

    @start: () =>
        address = Configuration.getCommandLineParameter("serviceConfig")
        name = Configuration.getCommandLineParameter("name")
        isConsoleLogEnabled = Configuration.getCommandLineParameter "forceConsoleLog"
        console.log "GUI starting: ", name
        console.log "Config-service address: ", address
        
        VirtDBConnector.onAddress VirtDBConnector.ALL_TYPE, VirtDBConnector.ALL_TYPE, (name, addresses, svcType, connectionType) =>
            Endpoints.onEndpoint name, svcType, connectionType, addresses

        VirtDBConnector.onAddress Const.ENDPOINT_TYPE.CONFIG, Const.SOCKET_TYPE.REQ_REP, (name, addresses) =>
            Endpoints.onEndpoint name, Const.ENDPOINT_TYPE.CONFIG, addresses
            Configuration.init()
            CacheHandler.init()
            
        VirtDBConnector.onAddress Const.ENDPOINT_TYPE.LOG_RECORD, Const.SOCKET_TYPE.PUB_SUB, (name, addresses) =>
            Endpoints.onEndpoint name, Const.ENDPOINT_TYPE.LOG_RECORD, addresses
            DiagConnector.connect()
        
        VirtDBConnector.onAddress Const.ENDPOINT_TYPE.COLUMN, Const.SOCKET_TYPE.PUB_SUB, (name, addresses) =>
            Endpoints.onEndpoint name, Const.ENDPOINT_TYPE.COLUMN, addresses
        
        VirtDBConnector.subscribe Const.ENDPOINT_TYPE.CONFIG, ConfigService.onPublishedConfig, name
        
        VirtDBConnector.connect(name, address)
        
        VirtDBConnector.log.enableConsoleLog isConsoleLogEnabled is true

module.exports = VirtDBLoader
