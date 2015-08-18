FieldData = require("virtdb-connector").FieldData
log = (require "virtdb-connector").log
V_ = log.Variable

class ColumnReceiver
    _columns: null
    _readyCallback: null
    _fields: null
    _fieldIndices: null
    _receivedColumnCount: null

    finishedColumns = null

    constructor: (@_readyCallback, @_fields) ->
        @_receivedColumnCount = 0
        @_columns = []
        @_fieldIndices = {}
        i = 0;
        for field in @_fields
            fieldName = @_fields[i]
            @_fieldIndices[fieldName] = i
            @_columns[i] = null
            ++i

        finishedColumns = new Set

    add: (column, onFinished) =>
        if finishedColumns.has(column.Name)
            log.warn "Unexpected column data on column:", V_ column.Name,
                "(End of data has already been reported earlier.)"
            return

        @_add column.Name, FieldData.get column
        if column.EndOfData
            finishedColumns.add column.Name
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
        @_columns[@_fieldIndices[columnName]] ?= {}
        column = @_columns[@_fieldIndices[columnName]]
        column.Name ?= columnName
        if column.Data?
            # Append the new data to the already received data.
            column.Data = column.Data.concat data
        else
            column.Data = data

    _isAllColumnReceived: () =>
        return finishedColumns.size >= @_fields.length

    @createInstance: (onReady, fields) =>
        return new ColumnReceiver onReady, fields

module.exports = ColumnReceiver
