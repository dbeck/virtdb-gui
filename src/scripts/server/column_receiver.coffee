FieldData = require("virtdb-connector").FieldData
log = (require "virtdb-connector").log
V_ = log.Variable

class ColumnReceiver
    _columns: null
    _readyCallback: null
    _fields: null
    _fieldIndices: null
    _finishedColumns: null

    constructor: (@_readyCallback, @_fields) ->
        @_columns = []
        @_fieldIndices = {}
        i = 0;
        for field in @_fields
            fieldName = @_fields[i]
            @_fieldIndices[fieldName] = i
            @_columns[i] = null
            ++i

        @_finishedColumns = new Set

    add: (column, onFinished) =>
        columnName = column.Name
        unless @_contains columnName
            log.warn "Received data on unexpected column:", V_ columnName
            return

        if @_finishedColumns.has(columnName)
            log.warn "Unexpected column data on column:", V_ columnName,
                "(End of data has already been reported earlier.)"
            return

        @_add columnName, FieldData.get column
        if column.EndOfData
            @_finishedColumns.add columnName
            if @_isAllColumnReceived()
                onFinished?()
                @_readyCallback @_columns
        return

    _contains: (columnName) =>
        for field in @_fields
            if field is columnName
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
        return @_finishedColumns.size >= @_fields.length

    @createInstance: (onReady, fields) =>
        return new ColumnReceiver onReady, fields

module.exports = ColumnReceiver
