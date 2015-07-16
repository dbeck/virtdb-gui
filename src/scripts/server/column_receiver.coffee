FieldData = require("virtdb-connector").FieldData
log = (require "virtdb-connector").log
V_ = log.Variable

class ColumnReceiver
    _columns: null
    _readyCallback: null
    _fields: null
    _columnEndOfData: null
    _fieldIndices: null
    _receivedColumnCount: null

    constructor: (@_readyCallback, @_fields) ->
        @_receivedColumnCount = 0
        @_columns = []
        @_columnEndOfData = {}
        @_fieldIndices = {}
        i = 0;
        for field in @_fields
            fieldName = @_fields[i]
            @_fieldIndices[fieldName] = i
            @_columnEndOfData[fieldName] = false
            @_columns[i] = null
            ++i

    add: (column, onFinished) =>
        if @_columns[@_fieldIndices[column.Name]]?
            return
        @_add column.Name, FieldData.get column
        @_columnEndOfData[column.Name] = column.EndOfData
        @_receivedColumnCount++
        if @_isAllColumnReceived()
            onFinished?()
            @_readyCallback @_columns
        return

    _contains: (columnName) =>
        for column in @_columns
            if column.Name == columnName
                return true
        return false

    _add: (columnName, data) =>
        @_columns[@_fieldIndices[columnName]] =
            Name: columnName
            Data: data

    _isAllColumnReceived: () =>
        return @_fields.length <= @_receivedColumnCount

    @createInstance: (onReady, fields) =>
        return new ColumnReceiver onReady, fields

module.exports = ColumnReceiver
