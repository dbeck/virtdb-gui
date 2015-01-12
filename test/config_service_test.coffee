ConfigService = require "../src/scripts/server/config_service"
convert = (require "virtdb-connector").Convert
util = require "util"

chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");
chai.use sinonChai

COMPONENT = "component"

CONFIG_MESSAGE_ONE_SCOPE = [
    Name: "KEY1"
    Data:
        Value:
            Type: "STRING"
            Value: ["VALUE1"]
        Scope:
            Type: "STRING"
            Value: ["SCOPE1"]
        Required:
            Type: "BOOL"
            Value: [true]
        Default:
            Type: "UINT32"
            Value: ["VALUE60"]
]

CONFIG_MESSAGE_ONE_SCOPE_RAW =
    Name: COMPONENT,
    ConfigData: [
        Key: '',
        Children: [
            Key: 'KEY1',
            Children: [
                Key: 'Value',
                Value:
                    Type: 'STRING',
                    StringValue: []
            ,
                Key: 'Scope',
                Value:
                    Type: 'STRING',
                    StringValue: ['SCOPE1']
            ,
                Key: 'Required',
                Value:
                    Type: 'BOOL',
                    BoolValue: [true]
            ,
                Key: 'Default',
                Value:
                    Type: 'UINT32',
                    UInt32Value: ['VALUE60']
            ]
        ]
    ,
        Key: 'SCOPE1',
        Children: [
            Key: 'KEY1',
            Value:
                Type: 'STRING',
                StringValue: ['VALUE1']
        ]
    ]

EMPTY_MESSAGE =
    Name: "config-convert-test"
    ConfigData: []

describe "ConfigService", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()

    afterEach =>
        sandbox.restore()

    it "_processGetConfigMessage should do the transformation right when message is empty", ->
        result = ConfigService._processGetConfigMessage EMPTY_MESSAGE
        expect(result).to.be.null

    it "_processGetConfigMessage should do the transformation right when message is correct", ->
        result = ConfigService._processGetConfigMessage JSON.parse JSON.stringify CONFIG_MESSAGE_ONE_SCOPE_RAW
        result.should.be.deep.equal CONFIG_MESSAGE_ONE_SCOPE

    it "_processSetConfigMessage should do the transformation right when message is correct", ->
        result = ConfigService._processSetConfigMessage COMPONENT, JSON.parse JSON.stringify CONFIG_MESSAGE_ONE_SCOPE
        result.should.be.deep.equal CONFIG_MESSAGE_ONE_SCOPE_RAW
