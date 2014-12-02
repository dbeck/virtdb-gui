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
        @IsNull.push (value == null)

    pushArray: (data) =>
        @StringValue = data.StringValue
        for item, index in data.IsNull
            @StringValue[index] = null unless item?

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
        @Int32Value.push value
        @IsNull.push (value == null)

    pushArray: (data) =>
        @Int32Value = data.Int32Value
        for item, index in data.IsNull
            @Int32Value[index] = null unless item?

    getArray: () =>
        @Int32Value

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
        @Int64Value.push value
        @IsNull.push (value == null)

    pushArray: (data) =>
        @Int64Value = data.Int64Value
        for item, index in data.IsNull
            @Int64Value[index] = null unless item?

    getArray: () =>
        @Int64Value

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
        @UInt32Value.push value
        @IsNull.push (value == null)

    pushArray: (data) =>
        @UInt32Value = data.UInt32Value
        for item, index in data.IsNull
            @UInt32Value[index] = null unless item?

    getArray: () =>
        @UInt32Value

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
        @UInt64Value.push value
        @IsNull.push (value == null)

    pushArray: (data) =>
        @UInt64Value = data.UInt64Value
        for item, index in data.IsNull
            @UInt64Value[index] = null unless item?

    getArray: () =>
        @UInt64Value

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
        @DoubleValue.push value
        @IsNull.push (value == null)

    pushArray: (data) =>
        @DoubleValue = data.DoubleValue
        for item, index in data.IsNull
            @DoubleValue[index] = null unless item?

    getArray: () =>
        @DoubleValue

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
        @FloatValue.push value
        @IsNull.push (value == null)

    pushArray: (data) =>
        @FloatValue = data.FloatValue
        for item, index in data.IsNull
            @FloatValue[index] = null unless item?

    getArray: () =>
        @FloatValue

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
        @BoolValue.push value
        @IsNull.push (value == null)

    pushArray: (data) =>
        @BoolValue = data.BoolValue
        for item, index in data.IsNull
            @BoolValue[index] = null unless item?

    getArray: () =>
        @BoolValue

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
        @BytesValue.push value
        @IsNull.push (value == null)

    pushArray: (data) =>
        @BytesValue = data.BytesValue
        for item, index in data.IsNull
            @BytesValue[index] = null unless item?

    getArray: () =>
        @BytesValue

    length: =>
        @BytesValue.length

    get: (index) =>
        if !@IsNull[index]
            @BytesValue[index]
        else
            null

module.exports = FieldData
