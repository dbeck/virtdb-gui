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

        @_finishedColumns = {}

    add: (column, onFinished) =>
        columnName = column.Name
        unless @_expected columnName
            log.warn "Received data on unexpected column:", V_ columnName
            return

        if @_finishedColumns[columnName]?
            log.warn "Unexpected column data on column:", V_ columnName,
                "(End of data has already been reported earlier.)"
            return

        @_add columnName, FieldData.get column
        if column.EndOfData
            @_finishedColumns[columnName] = true    # The value doesn't matter, as we are using it as a set.
            if @_isAllColumnReceived()
                onFinished?()
                @_readyCallback @_columns
        return

    _expected: (incomingColumnName) =>
        for field in @_fields
            if field is incomingColumnName
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
        return Object.keys(@_finishedColumns).length >= @_fields.length

    @createInstance: (onReady, fields) =>
        return new ColumnReceiver onReady, fields

module.exports = ColumnReceiver
