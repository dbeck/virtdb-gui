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
            metadataHandler = new MetadataHandler
            metadataHandler.getTableMetadata provider, tableName, (metadataMessage) =>
                tableMeta = metadataMessage.Tables[0]
                @_columnReceiver = new ColumnReceiver(onData, tableMeta.Fields)
                addresses = EndpointServiceConnector.getInstance().getComponentAddresses provider
                queryAddr = addresses[Const.ENDPOINT_TYPE.QUERY][Const.SOCKET_TYPE.PUSH_PULL]
                columnAddr = addresses[Const.ENDPOINT_TYPE.COLUMN][Const.SOCKET_TYPE.PUB_SUB]
                connection = new DataConnection(queryAddr[0], columnAddr[0])
                connection.getData tableMeta.Schema, tableMeta.Name, tableMeta.Fields, count, (column) =>
                    @_columnReceiver.add column
        catch ex
            log.error V_(ex)
            throw ex

module.exports = DataHandler
