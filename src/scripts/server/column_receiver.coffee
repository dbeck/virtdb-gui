FieldData = require "./fieldData"

class ColumnReceiver
    _columns: null
    _readyCallback: null
    _fields: null
    _columnEndOfData: null

    constructor: (@_readyCallback, @_fields) ->
        @_columns = []
        @_columnEndOfData = {}
        for field in @_fields
            @_columnEndOfData[field.name] = false

    add: (column) =>
        @_add column.Name, FieldData.get column
        @_columnEndOfData[column.Name] = column.EndOfData
        if @_checkReceivedColumns()
            @_readyCallback @_columns
        return

    _contains: (columnName) =>
        for column in @_columns
            if column.Name == columnName
                return true
        return false

    _add: (columnName, data) =>
        @_columns.push
            Name: columnName
            Data: data

    _checkReceivedColumns: () =>
        @_fields.length == @_columns.length

module.exports = ColumnReceiver
