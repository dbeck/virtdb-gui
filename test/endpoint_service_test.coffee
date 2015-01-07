zmq = require "zmq"
VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Constants
Proto = (require "virtdb-proto")
EndpointServiceConnector = require "../src/scripts/server/endpoint_service"
Config = require "../src/scripts/server/config"

chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");

chai.use sinonChai

NAME = "GUI_TEST"

SOCKET_MSG = "buffer"
SOCKET = "socket"

EP_MESSAGE =
    Endpoints: [
        Name: "ENDPOINT1"
        SvcType: "TYPE1"
        Connections: ["conn1", "conn2"]
    ,
        Name: "ENDPOINT2"
        SvcType: "TYPE2"
        Connections: ["conn3", "conn4"]
    ]

NEW_ENDPOINT =
    Endpoints: [
        Name: "ENDPOINT3"
        SvcType: "TYPE3"
        Connections: ["conn5", "conn6"]

    ]

MODIFIED_ENDPOINT =
    Endpoints: [
        Name: "ENDPOINT2"
        SvcType: "TYPE2"
        Connections: ["conn5", "conn6"]
    ]

NEW_EPLIST =
    Endpoints: [
        Name: "ENDPOINT1"
        SvcType: "TYPE1"
        Connections: ["conn1", "conn2"]
    ,
        Name: "ENDPOINT2"
        SvcType: "TYPE2"
        Connections: ["conn3", "conn4"]
    ,
        Name: NAME
    ,
        Name: "ENDPOINT3"
        SvcType: "TYPE3"
        Connections: ["conn5", "conn6"]
    ]

MODIFIED_EPLIST =
    Endpoints: [
        Name: "ENDPOINT1"
        SvcType: "TYPE1"
        Connections: ["conn1", "conn2"]
    ,
        Name: NAME
    ,
        Name: "ENDPOINT2"
        SvcType: "TYPE2"
        Connections: ["conn5", "conn6"]
    ]

EPLIST =
    Endpoints: [
        Name: "ENDPOINT1"
        SvcType: "TYPE1"
        Connections: ["conn1", "conn2"]
    ,
        Name: "ENDPOINT2"
        SvcType: "TYPE2"
        Connections: ["conn3", "conn4"]
    ,
        Name: NAME
    ]


describe "EndpointServiceConnector", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub(VirtDBConnector, "log")

    afterEach =>
        EndpointServiceConnector.reset()
        sandbox.restore()

    it "should set the address", ->
        address = "ADDRESS"
        EndpointServiceConnector.setAddress address
        EndpointServiceConnector._address.should.be.deep.equal address

    it "should reset the connector", ->
        instance = "INSTANCE"
        EndpointServiceConnector._instance = instance
        EndpointServiceConnector.reset()
        expect(EndpointServiceConnector._instance).to.be.null

    it "_onMesssage should work and subscribe if no sub socket", ->
        endpointMessageParseStub = sandbox.stub Proto.service_config, "parse"
        endpointMessageParseStub.returns JSON.parse JSON.stringify EP_MESSAGE
        configGetNameStub = sandbox.stub Config, "getCommandLineParameter"
        configGetNameStub.returns NAME

        epSrv = new EndpointServiceConnector
        subscribeStub = sandbox.stub epSrv, "_subscribeEndpoints"
        epSrv._onMessage SOCKET_MSG

        endpointMessageParseStub.should.have.been.calledOnce
        endpointMessageParseStub.should.have.been.calledWithExactly SOCKET_MSG, "virtdb.interface.pb.Endpoint"
        configGetNameStub.should.have.been.calledOnce
        configGetNameStub.should.have.been.calledWithExactly "name"
        epSrv.endpoints.should.be.deep.equal EPLIST.Endpoints
        subscribeStub.should.have.been.calledOnce

    it "_onMesssage should work and not subscribe if sub socket exists", ->
        endpointMessageParseStub = sandbox.stub Proto.service_config, "parse"
        endpointMessageParseStub.returns JSON.parse JSON.stringify EP_MESSAGE
        configGetNameStub = sandbox.stub Config, "getCommandLineParameter"
        configGetNameStub.returns NAME

        epSrv2 = new EndpointServiceConnector
        subscribeStub = sandbox.stub epSrv2, "_subscribeEndpoints"
        epSrv2.pubsubSocket = SOCKET
        epSrv2._onMessage SOCKET_MSG

        endpointMessageParseStub.should.have.been.calledOnce
        endpointMessageParseStub.should.have.been.calledWithExactly SOCKET_MSG, "virtdb.interface.pb.Endpoint"
        configGetNameStub.should.have.been.calledOnce
        configGetNameStub.should.have.been.calledWithExactly "name"
        epSrv2.endpoints.should.be.deep.equal EPLIST.Endpoints
        subscribeStub.should.have.been.not.calledOnce

    it "_handlePublished message should add the new endpoint to the list", ->
        epSrv = new EndpointServiceConnector
        epSrv.endpoints = JSON.parse JSON.stringify EPLIST.Endpoints
        epSrv._handlePublishedMessage NEW_ENDPOINT
        epSrv.endpoints.should.be.deep.equal NEW_EPLIST.Endpoints

    it "_handlePublished message should modify the endpoint list", ->
        epSrv = new EndpointServiceConnector
        epSrv.endpoints = JSON.parse JSON.stringify EPLIST.Endpoints
        epSrv._handlePublishedMessage MODIFIED_ENDPOINT
        epSrv.endpoints.should.be.deep.equal MODIFIED_EPLIST.Endpoints

    it "_onPublishedMessage should parse the message and call the handler method", ->
        endpointMessageParseStub = sandbox.stub Proto.service_config, "parse"
        endpointMessageParseStub.returns JSON.parse JSON.stringify EP_MESSAGE

        epSrv = new EndpointServiceConnector
        handleMessageStub = sandbox.stub epSrv, "_handlePublishedMessage"
        epSrv._onPublishedMessage "channel", SOCKET_MSG

        endpointMessageParseStub.should.have.been.calledOnce
        endpointMessageParseStub.should.have.been.calledWithExactly SOCKET_MSG, "virtdb.interface.pb.Endpoint"
        handleMessageStub.should.have.been.calledOnce
        handleMessageStub.should.have.been.calledWithExactly EP_MESSAGE

    it "_subscribeEndpoints should subscribe to the endpoint service", ->
        epSrv = new EndpointServiceConnector

        onPubMsgStub = sandbox.stub epSrv, "_onPublishedMessage"
        getSrvCfgAddressStub = sandbox.stub epSrv, "getServiceConfigAddresses"
        ADDRESS = "ADDRESSsSSSSSssss"
        ADDRESS_OBJ =
            ENDPOINT:
                PUB_SUB: ADDRESS
        getSrvCfgAddressStub.returns ADDRESS_OBJ

        fakeZmqSocket =
            connect: () ->
            on: () ->
            subscribe: () ->

        fakeSocket = sandbox.stub zmq, "socket"
        fakeSocket.returns fakeZmqSocket

        zmqMock = sandbox.mock fakeZmqSocket
        zmqMock.expects("connect").calledWith ADDRESS
        zmqMock.expects("on").calledWithExactly "message", epSrv._onPublishedMessage
        zmqMock.expects("subscribe").calledWithExactly Const.EVERY_CHANNEL

        epSrv._subscribeEndpoints()

        fakeSocket.should.have.been.deep.calledWith Const.ZMQ_SUB
        zmqMock.verify()
