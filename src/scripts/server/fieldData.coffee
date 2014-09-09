class FieldData
    @createInstance: (name, type) ->
        switch type
            when "STRING"
                new StringFieldData(name, type)
            when "INT32"
                new Int32FieldData(name, type)
            when "INT64"
                new Int64FieldData(name, type)
            when "UINT32"
                new UInt32FieldData(name, type)
            when "UINT64"
                new UInt64FieldData(name, type)
            when "DOUBLE"
                new DoubleFieldData(name, type)
            when "FLOAT"
                new FloatFieldData(name, type)
            when "BOOL"
                new BoolFieldData(name, type)
            when "BYTES"
                new BytesFieldData(name, type)
            else # "DATE", "TIME", "DATETIME", "NUMERIC", "INET4", "INET6", "MAC", "GEODATA"
                new StringFieldData(name, type)

    @createInstance2: (field) =>
        @createInstance(field.name, field.Desc.Type)

    @get: (data) =>
        local = @createInstance data.Data.Name, data.Data.Type
        local.pushArray data.Data
        return local.getArray()

    constructor: (@FieldName, @Type) ->
        @IsNull = new Array()

    # Call from not supported descendant classes only
    push: (value) =>
        @IsNull.push true

    reset: =>
        @IsNull = new Array()

class StringFieldData extends FieldData
    constructor: (@FieldName, @Type) ->
        super
        @StringValue = new Array()

    push: (value) =>
        @StringValue.push value
        @IsNull.push (value == "")

    pushArray: (data) =>
        @StringValue = data.StringValue
        for item, index in data.IsNull
            @StringValue[index] = "" unless item?

    getArray: () =>
        @StringValue

    length: =>
        @StringValue.length

    get: (index) =>
        if !@IsNull[index]
            @StringValue[index]
        else
            null

    reset: =>
        super
        @StringValue = new Array()

# Not yet supported - can only store null values
class Int32FieldData extends FieldData
    constructor: (@FieldName, @Type) ->
        super
        @Int32Value = new Array()

    push: (value) =>
        @Int32Value.push 0
        super

    length: =>
        @Int32Value.length

    get: (index) =>
        if !@IsNull[index]
            @Int32Value[index]
        else
            null

# Not yet supported - can only store null values
class Int64FieldData extends FieldData
    constructor: (@FieldName, @Type) ->
        super
        @Int64Value = new Array()

    push: (value) =>
        @Int64Value.push 0
        super

    length: =>
        @Int64Value.length

    get: (index) =>
        if !@IsNull[index]
            @Int64Value[index]
        else
            null

# Not yet supported - can only store null values
class UInt32FieldData extends FieldData
    constructor: (@FieldName, @Type) ->
        super
        @UInt32Value = new Array()

    push: (value) =>
        @UInt32Value.push 0
        super

    length: =>
        @UInt32Value.length

    get: (index) =>
        if !@IsNull[index]
            @UInt32Value[index]
        else
            null

# Not yet supported - can only store null values
class UInt64FieldData extends FieldData
    constructor: (@FieldName, @Type) ->
        super
        @UInt64Value = new Array()

    push: (value) =>
        @UInt64Value.push 0
        super

    length: =>
        @UInt64Value.length

    get: (index) =>
        if !@IsNull[index]
            @UInt64Value[index]
        else
            null

# Not yet supported - can only store null values
class DoubleFieldData extends FieldData
    constructor: (@FieldName, @Type) ->
        super
        @DoubleValue = new Array()

    push: (value) =>
        @DoubleValue.push 0
        super

    length: =>
        @DoubleValue.length

    get: (index) =>
        if !@IsNull[index]
            @DoubleValue[index]
        else
            null

# Not yet supported - can only store null values
class FloatFieldData extends FieldData
    constructor: (@FieldName, @Type) ->
        super
        @FloatValue = new Array()

    push: (value) =>
        @FloatValue.push 0
        super

    length: =>
        @FloatValue.length

    get: (index) =>
        if !@IsNull[index]
            @FloatValue[index]
        else
            null

# Not yet supported - can only store null values
class BoolFieldData extends FieldData
    constructor: (@FieldName, @Type) ->
        super
        @BoolValue = new Array()

    push: (value) =>
        @BoolValue.push false
        super

    length: =>
        @BoolValue.length

    get: (index) =>
        if !@IsNull[index]
            @BoolValue[index]
        else
            null

# Not yet supported - can only store null values
class BytesFieldData extends FieldData
    constructor: (@FieldName, @Type) ->
        super
        @BytesValue = new Array()

    push: (value) =>
        @BytesValue.push 0
        super

    length: =>
        @BytesValue.length

    get: (index) =>
        if !@IsNull[index]
            @BytesValue[index]
        else
            null

module.exports = FieldData
