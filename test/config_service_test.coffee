require("source-map-support").install()
ConfigService = require "../src/scripts/server/config_service"
ConfigServiceConnector = require "../src/scripts/server/config_service_connection"
VirtdbConnector = require "virtdb-connector"
convert = VirtdbConnector.Convert
log = VirtdbConnector.log
util = require "util"
Proto = (require "virtdb-proto")
Endpoints = require "../src/scripts/server/endpoints"

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
        sandbox.stub log, "debug"
        sandbox.stub log, "error"
        sandbox.stub log, "info"

    afterEach =>
        sandbox.restore()
        ConfigService._reset()

    describe "_processGetConfigMessage", ->

        it "should do the transformation right when message is empty", ->
            result = ConfigService._processGetConfigMessage EMPTY_MESSAGE
            expect(result).to.be.null

        it "should do the transformation right when message is correct", ->
            result = ConfigService._processGetConfigMessage JSON.parse JSON.stringify CONFIG_MESSAGE_ONE_SCOPE_RAW
            result.should.be.deep.equal CONFIG_MESSAGE_ONE_SCOPE

    describe "_processSetConfigMessage", ->

        it "should do the transformation right when message is correct", ->
            result = ConfigService._processSetConfigMessage COMPONENT, JSON.parse JSON.stringify CONFIG_MESSAGE_ONE_SCOPE
            result.should.be.deep.equal CONFIG_MESSAGE_ONE_SCOPE_RAW

    describe "subscribeToConfigs", ->

        it "should save the callback", ->
            callback = "Some callback or whatever"
            ConfigService.subscribeToConfigs callback
            ConfigService._subscriptionListeners.should.have.deep.contain callback

    describe "sendConfigTemplate", ->

        it "should send the converted config template", ->
            ADDRESSES = ["addr1", "addr2"]
            CONFIG = "cfg"

            conn = sinon.createStubInstance ConfigServiceConnector
            createInstanceStub = sandbox.stub ConfigServiceConnector, "createInstance"
            createInstanceStub.returns conn
            convertStub = sandbox.stub VirtdbConnector.Convert, "TemplateToOld"
            endpointsGetConfigServiceAddressStub = sandbox.stub Endpoints, "getConfigServiceAddress"
            endpointsGetConfigServiceAddressStub.returns ADDRESSES
            convertStub.returns CONFIG

            ConfigService.sendConfigTemplate CONFIG

            convertStub.should.have.been.calledOnce
            convertStub.should.have.been.calledWithExactly CONFIG
            conn.sendConfig.should.have.been.calledOnce
            conn.sendConfig.should.have.been.calledWithExactly CONFIG
            createInstanceStub.should.have.been.calledOnce
            createInstanceStub.should.have.been.calledWithExactly ADDRESSES

    describe "sendConfig", ->

        it "should send the converted config if there's no saved config", ->
            ADDRESSES = ["addr1", "addr2"]
            CONFIG = "cfg"
            COMPONENT = "com"

            conn = sinon.createStubInstance ConfigServiceConnector
            createInstanceStub = sandbox.stub ConfigServiceConnector, "createInstance"
            createInstanceStub.returns conn
            convertStub = sandbox.stub ConfigService, "_processSetConfigMessage"
            convertStub.returns CONFIG
            endpointsGetConfigServiceAddressStub = sandbox.stub Endpoints, "getConfigServiceAddress"
            endpointsGetConfigServiceAddressStub.returns ADDRESSES

            ConfigService._savedConfigs = {}
            ConfigService.sendConfig COMPONENT, CONFIG

            convertStub.should.have.been.calledOnce
            convertStub.should.have.been.calledWithExactly COMPONENT, CONFIG
            conn.sendConfig.should.have.been.calledOnce
            conn.sendConfig.should.have.been.calledWithExactly CONFIG
            createInstanceStub.should.have.been.calledOnce
            createInstanceStub.should.have.been.calledWithExactly ADDRESSES

        it "should send the converted config if saved config exists but different", ->
            ADDRESSES = ["addr1", "addr2"]
            CONFIG1 = "cfg1"
            CONFIG2 = "cfg2"
            COMPONENT = "com"

            conn = sinon.createStubInstance ConfigServiceConnector
            createInstanceStub = sandbox.stub ConfigServiceConnector, "createInstance"
            createInstanceStub.returns conn
            convertStub = sandbox.stub ConfigService, "_processSetConfigMessage"
            convertStub.returns CONFIG1
            endpointsGetConfigServiceAddressStub = sandbox.stub Endpoints, "getConfigServiceAddress"
            endpointsGetConfigServiceAddressStub.returns ADDRESSES

            ConfigService._savedConfigs[COMPONENT] = CONFIG2
            ConfigService.sendConfig COMPONENT, CONFIG1

            convertStub.should.have.been.calledOnce
            convertStub.should.have.been.calledWithExactly COMPONENT, CONFIG1
            conn.sendConfig.should.have.been.calledOnce
            conn.sendConfig.should.have.been.calledWithExactly CONFIG1
            createInstanceStub.should.have.been.calledOnce
            createInstanceStub.should.have.been.calledWithExactly ADDRESSES

        it "should send the converted config if saved config exists but different", ->
            ADDRESSES = ["addr1", "addr2"]
            CONFIG1 = "cfg1"
            CONFIG2 = "cfg2"
            COMPONENT = "com"

            conn = sinon.createStubInstance ConfigServiceConnector
            createInstanceStub = sandbox.stub ConfigServiceConnector, "createInstance"
            createInstanceStub.returns conn
            convertStub = sandbox.stub ConfigService, "_processSetConfigMessage"
            convertStub.returns CONFIG1
            endpointsGetConfigServiceAddressStub = sandbox.stub Endpoints, "getConfigServiceAddress"
            endpointsGetConfigServiceAddressStub.returns ADDRESSES

            ConfigService._savedConfigs[COMPONENT] = CONFIG1
            ConfigService.sendConfig COMPONENT, CONFIG1

            convertStub.should.not.have.been.called
            conn.sendConfig.should.not.have.been.called
            createInstanceStub.should.have.been.calledOnce
            createInstanceStub.should.have.been.calledWithExactly ADDRESSES

    describe "getConfig", ->

        it "should get the config", ->
            ADDRESSES = ["addr1", "addr2"]
            CONFIG = "cfg"
            COMPONENT = "com"
            SOCK_CONFIG =
                Name: COMPONENT
                Config: CONFIG

            conn = sinon.createStubInstance ConfigServiceConnector
            conn.getConfig.callsArgWith 1, SOCK_CONFIG
            createInstanceStub = sandbox.stub ConfigServiceConnector, "createInstance"
            createInstanceStub.returns conn
            convertStub = sandbox.stub ConfigService, "_processGetConfigMessage"
            convertStub.returns CONFIG
            endpointsGetConfigServiceAddressStub = sandbox.stub Endpoints, "getConfigServiceAddress"
            endpointsGetConfigServiceAddressStub.returns ADDRESSES
            onConfig = sandbox.spy()

            ConfigService._savedConfigs = {}
            ConfigService.getConfig COMPONENT, onConfig

            convertStub.should.have.been.calledOnce
            convertStub.should.have.been.calledWithExactly SOCK_CONFIG
            conn.getConfig.should.have.been.calledOnce
            conn.getConfig.should.have.been.calledWith COMPONENT
            createInstanceStub.should.have.been.calledOnce
            createInstanceStub.should.have.been.calledWithExactly ADDRESSES
            onConfig.should.have.been.calledOnce
            onConfig.should.have.been.calledWithExactly CONFIG
            ConfigService._savedConfigs.should.have.property COMPONENT, CONFIG

    describe "onPublishedConfig", ->

        it "should call the subscribed callbacks one callback", ->
            MSG = "msg"
            configParseStub = sandbox.stub Proto.service_config, "parse"
            configParseStub.returnsArg 0
            processStub = sandbox.stub ConfigService, "_processGetConfigMessage"
            processStub.returnsArg 0

            callback1 = sandbox.spy()
            ConfigService.subscribeToConfigs callback1

            ConfigService.onPublishedConfig "channel", MSG

            configParseStub.should.have.been.calledOnce
            configParseStub.should.have.been.calledWithExactly MSG, "virtdb.interface.pb.Config"
            callback1.should.have.been.calledOnce
            callback1.should.have.been.calledWithExactly MSG

        it "should call the subscribed callbacks multiple callback", ->
            MSG = "msg"
            configParseStub = sandbox.stub Proto.service_config, "parse"
            configParseStub.returnsArg 0
            processStub = sandbox.stub ConfigService, "_processGetConfigMessage"
            processStub.returnsArg 0

            callback1 = sandbox.spy()
            ConfigService.subscribeToConfigs callback1
            callback2 = sandbox.spy()
            ConfigService.subscribeToConfigs callback2
            callback3 = sandbox.spy()
            ConfigService.subscribeToConfigs callback3

            ConfigService.onPublishedConfig "channel", MSG

            configParseStub.should.have.been.calledOnce
            configParseStub.should.have.been.calledWithExactly MSG, "virtdb.interface.pb.Config"
            callback1.should.have.been.calledOnce
            callback1.should.have.been.calledWithExactly MSG
            callback2.should.have.been.calledOnce
            callback2.should.have.been.calledWithExactly MSG
            callback3.should.have.been.calledOnce
            callback3.should.have.been.calledWithExactly MSG
