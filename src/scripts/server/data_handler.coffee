CacheHandler = require "./cache_handler"
DataConnection = require "./data_connection"
MetadataHandler = require "./metadata_handler"
ColumnReceiver = require "./column_receiver"
log = (require "virtdb-connector").log
V_ = log.Variable

class DataHandler

    _columnReceiver: null

    constructor: ->

    getData: (provider, tableName, count, onData) =>
        try
            MetadataHandler.getTableMeta provider, tableName, (tableMeta) =>
                @_columnReceiver = new ColumnReceiver(onData, tableMeta.Fields)
                connection = new DataConnection "CIM"
                connection.getData tableMeta.Schema, tableMeta.Name, tableMeta.Fields, count, (column) =>
                    @_columnReceiver.add column

module.exports = DataHandler
