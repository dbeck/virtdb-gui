FieldData = require("virtdb-connector").FieldData
log = (require "virtdb-connector").log
V_ = log.Variable

class ColumnReceiver
    columns = null
    readyCallback = null
    fields = null
    fieldIndices = null
    finishedColumns = null

    constructor: (_readyCallback, _fields) ->
        readyCallback = _readyCallback
        fields = _fields
        columns = []
        fieldIndices = {}
        i = 0;
        for field in fields
            fieldName = fields[i]
            fieldIndices[fieldName] = i
            columns[i] = null
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
                readyCallback columns
        return

    _contains: (columnName) =>
        for column in columns
            if column.Name == columnName
                return true
        return false

    _add: (columnName, data) =>
        columns[fieldIndices[columnName]] ?= {}
        column = columns[fieldIndices[columnName]]
        column.Name ?= columnName
        if column.Data?
            # Append the new data to the already received data.
            column.Data = column.Data.concat data
        else
            column.Data = data

    _isAllColumnReceived: () =>
        return finishedColumns.size >= fields.length

    @createInstance: (onReady, fields) =>
        return new ColumnReceiver onReady, fields

module.exports = ColumnReceiver
