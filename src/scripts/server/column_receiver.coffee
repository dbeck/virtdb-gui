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
        @_add column.Name, FieldData.get column
        if column.EndOfData
            # Reached end of data for this column. We are done with that.
            delete @_columnEndOfData[column.Name]
        else
            @_columnEndOfData[column.Name] = false
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
        @_columns[@_fieldIndices[columnName]] ?= {}
        column = @_columns[@_fieldIndices[columnName]]
        column.Name ?= columnName
        if column.Data?
            # Append the new data to the already received data.
            column.Data = column.Data.concat data
        else
            column.Data = data

    _isAllColumnReceived: () =>
#        console.log "Called isAllColumnReceived...."
        for columnName, endOfData of @_columnEndOfData
#            console.log "#{columnName} end of data:", endOfData
            if endOfData
                # We are done with this column. Do not check this any more.
                delete @_columnEndOfData[columnName]
            else
                return false
        return @_fields.length <= @_receivedColumnCount

    @createInstance: (onReady, fields) =>
        return new ColumnReceiver onReady, fields

module.exports = ColumnReceiver
