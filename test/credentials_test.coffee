VirtDBConnector = require "virtdb-connector"
TokenManager = VirtDBConnector.TokenManager
SourceSystemCredential = VirtDBConnector.SourceSystemCredential
log = VirtDBConnector.log
Credentials = require "../src/scripts/server/credentials"

chai = require "chai"
expect = chai.expect
should = chai.should()
sinon = require "sinon"
sinonChai = require("sinon-chai");
chai.use sinonChai

LOGIN_TOKEN = "LT-212535353"
SRC_SYS_TOKEN = "SST-2122424313"
SRC_SYS_NAME = "component1"
TEMPLATE = [
    Name: "user"
    Type: "STRING"
,
    Name: "really"
    Type: "BOOLEAN"
,
    Name: "pass"
    Type: "PASSWORD"
]
CREDS = [
    Name: "user"
    Value: "Joska"
,
    Name: "really"
    Value: "true"
,
    Name: "pass"
    Value: "secret"
]
CREDENTIAL =
    NamedValues: CREDS
MERGED_CREDS = [
    Name: "user"
    Type: "STRING"
    Value: "Joska"
,
    Name: "really"
    Type: "BOOLEAN"
    Value: "true"
,
    Name: "pass"
    Type: "PASSWORD"
    Value: "secret"
]
ERROR_MSG = "Something went wrong"
ERROR = new Error ERROR_MSG

describe "Crendentials", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDBConnector.log, "info"
        sandbox.stub VirtDBConnector.log, "debug"
        sandbox.stub VirtDBConnector.log, "trace"
        sandbox.stub VirtDBConnector.log, "error"

    afterEach =>
        sandbox.restore()

    describe "getCredential", ->

        it "should get and return the template if it is available but there is no already stored credential", ->
            (sandbox.stub SourceSystemCredential, "getTemplate").yields null, TEMPLATE
            (sandbox.stub TokenManager, "getSourceSystemToken").yields null, SRC_SYS_TOKEN
            (sandbox.stub SourceSystemCredential, "getCredential").yields ERROR, null
            callback = sandbox.spy()
            Credentials.getCredential LOGIN_TOKEN, SRC_SYS_NAME, callback
            callback.should.have.been.calledWithExactly null, TEMPLATE

        it "should get and return the template if it is available but there is no source system token", ->
            (sandbox.stub SourceSystemCredential, "getTemplate").yields null, TEMPLATE
            (sandbox.stub TokenManager, "getSourceSystemToken").yields ERROR, null
            callback = sandbox.spy()
            Credentials.getCredential LOGIN_TOKEN, SRC_SYS_NAME, callback
            callback.should.have.been.calledWithExactly null, TEMPLATE

        it "should get and return the merged template/credential if both are available", ->
            (sandbox.stub SourceSystemCredential, "getTemplate").yields null, TEMPLATE
            (sandbox.stub TokenManager, "getSourceSystemToken").yields null, SRC_SYS_TOKEN
            (sandbox.stub SourceSystemCredential, "getCredential").yields null, CREDENTIAL
            callback = sandbox.spy()
            Credentials.getCredential LOGIN_TOKEN, SRC_SYS_NAME, callback
            callback.should.have.been.calledWithExactly null, MERGED_CREDS

        it "should return with error if any during getting template", ->
            (sandbox.stub SourceSystemCredential, "getTemplate").yields ERROR, null
            callback = sandbox.spy()
            Credentials.getCredential LOGIN_TOKEN, SRC_SYS_NAME, callback
            callback.should.have.been.calledWithExactly ERROR, null

    describe "setCredential", ->

        it "should get the source system token and set credential", ->
            (sandbox.stub TokenManager, "getSourceSystemToken").yields null, SRC_SYS_TOKEN
            setCredentialStub = sandbox.stub SourceSystemCredential, "setCredential"
            setCredentialStub.yields null, null
            callback = sandbox.spy()
            Credentials.setCredential LOGIN_TOKEN, SRC_SYS_NAME, CREDS, callback
            (sandbox.stub TokenManager, "createSourceSystemToken").should.not.have.been.called
            setCredentialStub.should.have.been.calledWith SRC_SYS_NAME, SRC_SYS_TOKEN, CREDENTIAL
            callback.should.have.been.calledWithExactly null

        it "should create new source system token and save credential", ->
            (sandbox.stub TokenManager, "getSourceSystemToken").yields ERROR, null
            (sandbox.stub TokenManager, "createSourceSystemToken").yields null, SRC_SYS_TOKEN
            setCredentialStub = sandbox.stub SourceSystemCredential, "setCredential"
            setCredentialStub.yields null, null
            callback = sandbox.spy()
            Credentials.setCredential LOGIN_TOKEN, SRC_SYS_NAME, CREDS, callback
            setCredentialStub.should.have.been.calledWith SRC_SYS_NAME, SRC_SYS_TOKEN, CREDENTIAL
            callback.should.have.been.calledWithExactly null

        it "should return with error if any during setting credential", ->
            (sandbox.stub TokenManager, "getSourceSystemToken").yields null, SRC_SYS_TOKEN
            setCredentialStub = sandbox.stub SourceSystemCredential, "setCredential"
            setCredentialStub.yields ERROR, null
            callback = sandbox.spy()
            Credentials.setCredential LOGIN_TOKEN, SRC_SYS_NAME, CREDS, callback
            setCredentialStub.should.have.been.calledWith SRC_SYS_NAME, SRC_SYS_TOKEN, CREDENTIAL
            callback.should.have.been.calledWithExactly ERROR

        it "should return with error if any during creating source system token", ->
            createSourceSystemTokenStub = sandbox.stub TokenManager, "createSourceSystemToken"
            createSourceSystemTokenStub.yields ERROR, null
            (sandbox.stub TokenManager, "getSourceSystemToken").yields ERROR, null
            setCredentialStub = sandbox.stub SourceSystemCredential, "setCredential"
            callback = sandbox.spy()
            Credentials.setCredential LOGIN_TOKEN, SRC_SYS_NAME, CREDS, callback
            createSourceSystemTokenStub.should.have.been.called
            setCredentialStub.should.not.have.been.called
            callback.should.have.been.calledWithExactly ERROR