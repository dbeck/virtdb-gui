VirtDBConnector = require "virtdb-connector"
MetadataHandler = require "../src/scripts/server/meta_data_handler"
DataHandler = require "../src/scripts/server/data_handler"
DataConnection = require "../src/scripts/server/data_connection"
CacheHandler = require "../src/scripts/server/cache_handler"
Config = require "../src/scripts/server/config"
ColumnReceiver = require "../src/scripts/server/column_receiver"
Endpoints = require "../src/scripts/server/endpoints"


chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");

chai.use sinonChai

describe "DataHandler", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDBConnector.log, "info"
        sandbox.stub VirtDBConnector.log, "debug"
        sandbox.stub VirtDBConnector.log, "trace"
        sandbox.stub VirtDBConnector.log, "error"

    afterEach =>
        sandbox.restore()

    # Not complete test, we should check that the final callback is called, also should test the column receiver class
    it "should request data from connection and give it to the column receiver", ->

        PROVIDER = "prov"
        TABLE = "table"
        SCHEMA = "schema"
        COUNT = 10
        FIELDS = ["field1", "field2", "field3"]
        METADATA =
            Tables: [
                Name: TABLE
                Schema: SCHEMA
                Fields: FIELDS
            ]
        ADDRESSES =
            QUERY: ["qaddr1", "qaddr2"]
            COLUMN: ["caddr1", "caddr2"]

        COLUMN = "column"

        onDataSpy = sinon.spy()
        metadataHandler = sinon.createStubInstance MetadataHandler
        metadataHandlerCreateInstanceStub = sandbox.stub MetadataHandler, "createInstance"
        metadataHandlerCreateInstanceStub.returns metadataHandler
        metadataHandler.getTableMetadata.callsArgWith 2, null, METADATA

        dataConnection = sinon.createStubInstance DataConnection
        dataConnectionCreateInstanceStub = sandbox.stub DataConnection, "createInstance"
        dataConnectionCreateInstanceStub.returns dataConnection
        dataConnection.getData.callsArgWith 4, COLUMN

        columnReceiver = sinon.createStubInstance ColumnReceiver
        columnReceiverCreateInstanceStub = sandbox.stub ColumnReceiver, "createInstance"
        columnReceiverCreateInstanceStub.returns columnReceiver
        onColumnSpy = sinon.spy()

        dataHandler = new DataHandler

        endpointsGetQueryAddressStub = sandbox.stub Endpoints, "getQueryAddress"
        endpointsGetQueryAddressStub.returns ADDRESSES.QUERY
        endpointsGetColumnAddressStub = sandbox.stub Endpoints, "getColumnAddress"
        endpointsGetColumnAddressStub.returns ADDRESSES.COLUMN

        dataHandler.getData PROVIDER, TABLE, COUNT, onDataSpy

        metadataHandler.getTableMetadata.should.calledOnce
        metadataHandler.getTableMetadata.should.calledWith PROVIDER, TABLE
        columnReceiverCreateInstanceStub.should.calledOnce
        columnReceiverCreateInstanceStub.should.calledWithExactly onDataSpy, FIELDS
        endpointsGetQueryAddressStub.should.calledOnce
        endpointsGetQueryAddressStub.should.calledWithExactly PROVIDER
        endpointsGetColumnAddressStub.should.calledOnce
        endpointsGetColumnAddressStub.should.calledWithExactly PROVIDER
        dataConnection.getData.should.calledWith SCHEMA, TABLE, FIELDS, COUNT
        columnReceiver.add.should.called
        columnReceiver.add.should.calledWithExactly COLUMN
        dataConnectionCreateInstanceStub.should.calledOnce
        dataConnectionCreateInstanceStub.should.calledWithExactly ADDRESSES.QUERY, ADDRESSES.COLUMN

    #should test provider addresses
