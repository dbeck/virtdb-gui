Config = require "../src/scripts/server/config"
ConfigService = require "../src/scripts/server/config_service"
convert = (require "virtdb-connector").Convert

chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");
chai.use sinonChai

CONFIG_MESSAGE =
    Name: "config-convert-test"
    ConfigData: [
        Key: 'GLOBAL'
        Value:
            Type: 'STRING'
        Children: [
            Key: 'Path'
            Value:
                Type: 'STRING'
                StringValue: [
                    '/usr/local/lib'
                ]
        ]
    ]
CONVERTED_MESSAGE = convert.ToObject convert.ToNew CONFIG_MESSAGE
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

    it "should give back null when calling getCommandLineParameter", ->
        commandLine = ["--name", "gui-name", "--trace", "--port=9999", "-s", "address", "--timeout=56"]
        Config._parseCommandLine commandLine
        Config.getCommandLineParameter("port").should.deep.equal(9999)
        Config.getCommandLineParameter("name").should.deep.equal("gui-name")
        Config.getCommandLineParameter("serviceConfig").should.deep.equal("address")
        Config.getCommandLineParameter("timeout").should.deep.equal(56)
        Config.getCommandLineParameter("trace").should.be.true

    it "should give back null when calling getCommandLineParameter with wrong key", ->
        commandLine = ["--name", "gui-name", "--trace", "--port=9999", "-s", "address", "--timeout=56"]
        Config._parseCommandLine commandLine
        expect(Config.getCommandLineParameter("kiscica")).to.be.null

    it "should give back the right config service parameter when calling getConfigServiceParameter", ->
        key = "KEY"
        value = "VALUE"
        Config._parameters[key] = value
        Config.getConfigServiceParameter(key).should.deep.equal(value)

    it "should give back null when calling getConfigServiceParameter with not existing key", ->
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
        console.log CONVERTED_MESSAGE
        handleConfig = sandbox.spy(Config, "_handleConfig");
        Config.onConfigReceived CONFIG_MESSAGE
        handleConfig.should.calledOnce
        handleConfig.should.calledWith(CONVERTED_MESSAGE)

    it "onConfigReceived should send back the template when not empty config received", ->
        defTemplateStub = sandbox.stub Config, "_getConfigTemplate"
        defTemplateStub.returns CONFIG_TEMPLATE
        cfgSrvSendSpy = sandbox.stub ConfigService, "sendConfigTemplate"
        Config.onConfigReceived EMPTY_MESSAGE
        cfgSrvSendSpy.should.have.been.deep.calledWith CONFIG_TEMPLATE


    #handleConfig
    #notifyListeners
