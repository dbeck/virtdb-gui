Configuration = require "./config"
ConfigService = require "./config_service"
EndpointServiceConnector = require "./endpoint_service"
DiagConnector = require "./diag_connector"
CacheHandler = require "./cache_handler"
VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Constants
async = require "async"

class VirtDBLoader

    @start: () =>
        address = Configuration.getCommandLineParameter("serviceConfig")
        name = Configuration.getCommandLineParameter("name")
        VirtDBConnector.onAddress Const.ENDPOINT_TYPE.CONFIG, Const.SOCKET_TYPE.REQ_REP, (name, addresses) =>
                console.log "Got config service addresses:", addresses
                ConfigService.setAddresses(addresses)
                Configuration.init()
        VirtDBConnector.subscribe Const.ENDPOINT_TYPE.CONFIG, ConfigService.onPublishedConfig, name
        VirtDBConnector.connect(name, address)

        EndpointServiceConnector.reset()
        EndpointServiceConnector.setAddress(address)
        EndpointServiceConnector.getInstance().addEndpointsReadyListener () ->
            DiagConnector.connect("diag-service")
            CacheHandler.init()

module.exports = VirtDBLoader
