Config = require "../src/scripts/server/config"
ConfigService = require "../src/scripts/server/config_service"
convert = (require "virtdb-connector").Convert

chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");
chai.use sinonChai

CONFIG_MESSAGE_ONE_SCOPE =
    Name: "config-convert-test"
    ConfigData: [
        Key: 'SCOPE1'
        Value:
            Type: 'STRING'
        Children: [
            Key: 'KEY1'
            Value:
                Type: 'STRING'
                StringValue: [
                    'VALUE1'
                ]
        ]
    ]
CONFIG_MESSAGE_TWO_SCOPE =
    Name: "config-convert-test"
    ConfigData: [
        Key: 'SCOPE1'
        Value:
            Type: 'STRING'
        Children: [
            Key: 'KEY1'
            Value:
                Type: 'STRING'
                StringValue: [
                    'VALUE1'
                ]
        ]
    ,
        Key: 'SCOPE2'
        Value:
            Type: 'STRING'
        Children: [
            Key: 'KEY1'
            Value:
                Type: 'STRING'
                StringValue: [
                    'VALUE2'
                ]
        ]
    ]
CONFIG_MESSAGE_ONE_SCOPE_TWO_VALUE =
    Name: "config-convert-test"
    ConfigData: [
        Key: 'SCOPE1'
        Value:
            Type: 'STRING'
        Children: [
            Key: 'KEY1'
            Value:
                Type: 'STRING'
                StringValue: [
                    'VALUE1'
                ]
        ,
            Key: 'KEY2'
            Value:
                Type: 'STRING'
                StringValue: [
                    'VALUE2'
                ]
        ]
    ]
CONVERTED_CONFIG_MESSAGE_ONE_SCOPE = convert.ToObject convert.ToNew CONFIG_MESSAGE_ONE_SCOPE
CONVERTED_CONFIG_MESSAGE_TWO_SCOPE = convert.ToObject convert.ToNew CONFIG_MESSAGE_TWO_SCOPE
CONVERTED_CONFIG_MESSAGE_ONE_SCOPE_TWO_VALUE = convert.ToObject convert.ToNew CONFIG_MESSAGE_ONE_SCOPE_TWO_VALUE

CONFIG_TEMPLATE =
    AppName: "NAME"
    Config: [
        VariableName: 'VAR'
        Type: 'STRING'
        Scope: "DEFAULT_SCOPE"
        Required: true
        Default: "DEFAULT_VALUE"
    ]
EMPTY_MESSAGE =
    Name: "config-convert-test"
    ConfigData: []

describe "Gui configuration handler", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        Config.reset()

    afterEach =>
        sandbox.restore()

    it "getCommandLineParameter should give back the right parameters", ->
        commandLine = ["--name", "gui-name", "--trace", "--port=9999", "-s", "address", "--timeout=56"]
        Config._parseCommandLine commandLine
        Config.getCommandLineParameter("port").should.deep.equal(9999)
        Config.getCommandLineParameter("name").should.deep.equal("gui-name")
        Config.getCommandLineParameter("serviceConfig").should.deep.equal("address")
        Config.getCommandLineParameter("timeout").should.deep.equal(56)
        Config.getCommandLineParameter("trace").should.be.deep.true

    it "getCommandLineParameter should give back false when trace is not given", ->
        commandLine = ["--name", "gui-name", "--port=9999", "-s", "address", "--timeout=56"]
        Config._parseCommandLine commandLine
        Config.getCommandLineParameter("trace").should.not.be.deep.true

    it "getCommandLineParameter should give back null when calling with wrong key", ->
        commandLine = ["--name", "gui-name", "--trace", "--port=9999", "-s", "address", "--timeout=56"]
        Config._parseCommandLine commandLine
        expect(Config.getCommandLineParameter("kiscica")).to.be.null

    it "getConfigServiceParameter should give back the right config service parameter when calling", ->
        key = "KEY"
        value = "VALUE"
        Config._parameters[key] = value
        Config.getConfigServiceParameter(key).should.deep.equal(value)

    it "getConfigServiceParameter should give back null when calling with not existing key", ->
        key = "KEY"
        value = "VALUE"
        Config._parameters[key] = value
        expect(Config.getConfigServiceParameter("kiscica")).to.be.null

    it "addConfigListener should call the callback with the parameter when it exists", ->
        key = "KEY"
        value = "VALUE"
        listener = sinon.spy()
        Config._parameters[key] = value

        Config.addConfigListener key, listener

        Config._configListeners.should.deep.property key
        Config._configListeners[key].should.deep.contain listener
        listener.should.have.been.deep.calledWith value

    it "addConfigListener should call the callback with the default parameter value when the parameter does not exist", ->
        key = "KEY"
        value = "VALUE"
        listener = sinon.spy()
        Config.DEFAULTS[key] = value

        Config.addConfigListener key, listener

        Config._configListeners.should.deep.property key
        Config._configListeners[key].should.deep.contain listener
        listener.should.have.been.deep.calledWith value

    it "addConfigListener should not call the callback without default and parameters", ->
        key = "KEY"
        value = "VALUE"
        kiscica = "kiscica"
        listener = sandbox.spy()
        Config._parameters[key] = value

        Config.addConfigListener kiscica, listener

        Config._configListeners.should.deep.property kiscica
        Config._configListeners[kiscica].should.deep.contain listener
        listener.should.have.been.not.calledWith value

    it "addConfigListener should do nothing at all when listener is null", ->
        kiscica = "kiscica"
        Config.addConfigListener kiscica, null

        Config._configListeners.should.not.deep.property kiscica

    it "onConfigReceived should call _handleConfig with the converted config message", ->
        handleConfig = sandbox.spy(Config, "_handleConfig");
        Config.onConfigReceived CONFIG_MESSAGE_ONE_SCOPE
        handleConfig.should.calledOnce
        handleConfig.should.calledWith(CONVERTED_CONFIG_MESSAGE_ONE_SCOPE)

    it "onConfigReceived should send back the template when not empty config received", ->
        defTemplateStub = sandbox.stub Config, "_getConfigTemplate"
        defTemplateStub.returns CONFIG_TEMPLATE
        cfgSrvSendSpy = sandbox.stub ConfigService, "sendConfigTemplate"
        Config.onConfigReceived EMPTY_MESSAGE
        cfgSrvSendSpy.should.have.been.deep.calledWith CONFIG_TEMPLATE

    it "_handleConfig should handle simple config message with one scope, one value", ->
        expectedKey = "SCOPE1/KEY1"
        expectedValue = "VALUE1"
        notifyListenersStub = sandbox.stub Config, "_notifyListeners"
        Config._handleConfig CONVERTED_CONFIG_MESSAGE_ONE_SCOPE

        Config._parameters.should.have.been.deep.property expectedKey
        Config._parameters[expectedKey].should.be.deep.equal expectedValue
        notifyListenersStub.should.have.been.calledOnce

    it "_handleConfig should handle simple config message with two scope, one value", ->
        scope1key1 = "SCOPE1/KEY1"
        value1 = "VALUE1"
        scope2key1 = "SCOPE2/KEY1"
        value2 = "VALUE2"
        notifyListenersStub = sandbox.stub Config, "_notifyListeners"
        Config._handleConfig CONVERTED_CONFIG_MESSAGE_TWO_SCOPE

        Config._parameters.should.have.been.deep.property scope1key1
        Config._parameters[scope1key1].should.be.deep.equal value1
        Config._parameters.should.have.been.deep.property scope2key1
        Config._parameters[scope2key1].should.be.deep.equal value2
        notifyListenersStub.should.have.been.calledOnce

    it "_handleConfig should handle simple config message with one scope, two value", ->
        scope1key1 = "SCOPE1/KEY1"
        value1 = "VALUE1"
        scope1key2 = "SCOPE1/KEY2"
        value2 = "VALUE2"
        notifyListenersStub = sandbox.stub Config, "_notifyListeners"
        Config._handleConfig CONVERTED_CONFIG_MESSAGE_ONE_SCOPE_TWO_VALUE

        Config._parameters.should.have.been.deep.property scope1key1
        Config._parameters[scope1key1].should.be.deep.equal value1
        Config._parameters.should.have.been.deep.property scope1key2
        Config._parameters[scope1key2].should.be.deep.equal value2
        notifyListenersStub.should.have.been.calledOnce

    it "_notifyListeners should call all callback which is registrated for an existing parameter", ->
        key1 = "key1"
        key2 = "key2"
        val1 = "val1"
        val2 = "val2"
        listener1 = sandbox.spy()
        listener2 = sandbox.spy()
        listener3 = sandbox.spy()

        Config._parameters[key1] = val1
        Config._parameters[key2] = val2
        Config._configListeners[key1] = [listener1]
        Config._configListeners[key2] = [listener2, listener3]

        Config._notifyListeners()

        listener1.should.have.been.deep.calledWith val1
        listener2.should.have.been.deep.calledWith val2
        listener3.should.have.been.deep.calledWith val2

    it "_notifyListeners should not call a callback which is registrated for a non-existing parameter", ->
        key1 = "key1"
        key2 = "key2"
        val1 = "val1"
        listener1 = sandbox.spy()
        listener2 = sandbox.spy()

        Config._parameters[key1] = val1
        Config._configListeners[key1] = [listener1]
        Config._configListeners[key2] = [listener2]

        Config._notifyListeners()

        listener2.should.not.have.been.called

    it "_notifyListeners should not do anything if parameters are empty", ->
        key1 = "key1"
        val1 = "val1"
        listener1 = sandbox.spy()

        Config._configListeners[key1] = [listener1]

        Config._notifyListeners()

        listener1.should.not.have.been.called
