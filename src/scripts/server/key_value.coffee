class KeyValue

    @parseJSON = (data) =>
        return @_processJSON(data)

    @_processJSON = (data) =>
        children = []
        for key, value of data
            obj = {}
            obj.Key = key
            if Object.keys(value).length is 2 and value.Type? and value.Value?
                obj.Value ?= {}
                obj.Value["Type"] = value.Type
                obj.Value[@_selectValue value] = value.Value
            else if typeof value is "object" and value isnt null
                obj.Children = @_processJSON value
            else
                console.error "Not well formed json"
            children.push obj
        return children

    @toJSON = (data) =>
        if not data?
            return data
        if data?.length and data.length is 0
            return {}
        return @_processKeyValue(data)

    @_processKeyValue = (data) =>
        result = {}
        if data.Value?
            valueType = @_selectValue data.Value
            result[data.Key] =
                Type: data.Value.Type
                Value: data.Value[valueType]
        else
            if data.Children.length isnt 0
                result[data.Key] = {}
                for child in data.Children
                    result[data.Key][child.Key] = (@_processKeyValue child)[child.Key]
        return result


    @_selectValue = (value) =>
        switch value.Type
            when "STRING"
                return "StringValue"
            when "INT32"
                return "Int32Value"
            when "INT64"
                return "Int64Value"
            when "UINT32"
                return "UInt32Value"
            when "UINT64"
                return "UInt64Value"
            when "DOUBLE"
                return "DoubleValue"
            when "FLOAT"
                return "FloatValue"
            when "BOOL"
                return "BoolValue"
            when "BYTES"
                return "BytesValue"
            else # "DATE", "TIME", "DATETIME", "NUMERIC", "INET4", "INET6", "MAC", "GEODATA"
                return "StringValue"

module.exports = KeyValue
