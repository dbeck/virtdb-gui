DataConnection = require "./data_connection"
MetadataHandler = require "./meta_data_handler"
ColumnReceiver = require "./column_receiver"
Const = (require "virtdb-connector").Const
Endpoints = require "./endpoints"

log = (require "virtdb-connector").log
V_ = log.Variable

class DataHandler

    _columnReceiver: null

    constructor: ->

    getData: (provider, tableName, count, onData) =>
        try
            metadataHandler = MetadataHandler.createInstance()
            metadataHandler.getTableMetadata provider, tableName, (err, metadataMessage) =>
                if err?
                    onData []
                    return
                tableMeta = metadataMessage.Tables[0]
                if not tableMeta?.Fields?.length > 0
                    log.error "Asking for data with no fields provided"
                    console.trace "Asking for data with no fields."
                    return
                @_columnReceiver = ColumnReceiver.createInstance onData, tableMeta.Fields
                connection = DataConnection.createInstance (Endpoints.getQueryAddress provider), (Endpoints.getColumnAddress provider), provider
                connection.getData tableMeta.Schema, tableMeta.Name, tableMeta.Fields, count, (column, onFinished) =>
                    @_columnReceiver.add column, onFinished
        catch ex
            log.error V_(ex)
            throw ex

    @createInstance: =>
        return new DataHandler

module.exports = DataHandler
