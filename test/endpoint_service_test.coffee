zmq = require "zmq"
VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Constants
Proto = (require "virtdb-proto")
EndpointServiceConnector = require "../src/scripts/server/endpoint_service"

chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");

chai.use sinonChai

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
