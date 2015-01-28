DataConnection = require "./data_connection"
MetadataHandler = require "./meta_data_handler"
ColumnReceiver = require "./column_receiver"
Const = (require "virtdb-connector").Constants
EndpointServiceConnector = require "./endpoint_service"


log = (require "virtdb-connector").log
V_ = log.Variable

class DataHandler

    _columnReceiver: null

    constructor: ->

    getData: (provider, tableName, count, onData) =>
        try
            metadataHandler = MetadataHandler.createInstance()
            metadataHandler.getTableMetadata provider, tableName, (metadataMessage) =>
                tableMeta = metadataMessage.Tables[0]
                @_columnReceiver = ColumnReceiver.createInstance onData, tableMeta.Fields
                addresses = @getProviderAddress provider
                connection = DataConnection.createInstance addresses.QUERY, addresses.COLUMN
                connection.getData tableMeta.Schema, tableMeta.Name, tableMeta.Fields, count, (column) =>
                    @_columnReceiver.add column
        catch ex
            log.error V_(ex)
            throw ex

    getProviderAddress: (provider) =>
        addresses = EndpointServiceConnector.getInstance().getComponentAddresses provider
        queryAddr = addresses[Const.ENDPOINT_TYPE.QUERY][Const.SOCKET_TYPE.PUSH_PULL]
        columnAddr = addresses[Const.ENDPOINT_TYPE.COLUMN][Const.SOCKET_TYPE.PUB_SUB]
        return address =
            QUERY: queryAddr[0]
            COLUMN: columnAddr[0]

    @createInstance: =>
        return new DataHandler

module.exports = DataHandler
