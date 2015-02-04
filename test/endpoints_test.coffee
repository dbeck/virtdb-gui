VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Constants
Endpoints = require "../src/scripts/server/endpoints"
util = require "util"

chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");

chai.use sinonChai

describe "Endpoints", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDBConnector.log, "info"
        sandbox.stub VirtDBConnector.log, "debug"
        sandbox.stub VirtDBConnector.log, "trace"
        sandbox.stub VirtDBConnector.log, "error"

    afterEach =>
        sandbox.restore()
        Endpoints._endpoints = []

    it "should store the newly received endpoint if it is the first one", ->
        NAME = "NAME"
        CONNTYPE = "REQ_REP"
        SVCTYPE = "DB_CONFIG"
        ADDRESSES = ["address1", "address2"]
     
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE, ADDRESSES
        
        Endpoints._endpoints.should.have.deep.property NAME
        Endpoints._endpoints[NAME].should.have.deep.property SVCTYPE
        Endpoints._endpoints[NAME][SVCTYPE].should.have.deep.property CONNTYPE, ADDRESSES
    
    it "should store the newly received endpoint if it is not the first one", ->
        NAME2 = "NAME2"
        CONNTYPE2 = "PUSH_PULL"
        SVCTYPE2 = "GET_LOGS"
        ADDRESSES2 = ["address11", "address12"]
      
        Endpoints.onEndpoint "NAME", "SVCTYPE", "CONNTYPE", "ADDRESSES"
        Endpoints.onEndpoint NAME2, SVCTYPE2, CONNTYPE2, ADDRESSES2
        
        Endpoints._endpoints.should.have.deep.property NAME2
        Endpoints._endpoints[NAME2].should.have.deep.property SVCTYPE2
        Endpoints._endpoints[NAME2][SVCTYPE2].should.have.deep.property CONNTYPE2, ADDRESSES2

    it "should delete the connection type if there's no address", ->
        NAME = "NAME"
        CONNTYPE = "REQ_REP"
        SVCTYPE = "DB_CONFIG"
        ADDRESSES = ["address1", "address2"]
        ADDRESS_EMPTY = []
            
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE, ADDRESSES
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE, ADDRESS_EMPTY
        Endpoints._endpoints.should.not.have.property NAME


    it "should delete only the affected connection type if there are more", ->
        NAME = "NAME"
        CONNTYPE1 = "REQ_REP"
        CONNTYPE2 = "PUSH_PULL"
        SVCTYPE = "DB_CONFIG"
        ADDRESSES = ["address1", "address2"]
        ADDRESS_EMPTY = []
            
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE1, ADDRESSES
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE2, ADDRESSES
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE2, ADDRESS_EMPTY

        Endpoints._endpoints[NAME][SVCTYPE].should.not.have.property CONNTYPE2
        Endpoints._endpoints[NAME][SVCTYPE].should.have.property CONNTYPE1

    it "should delete only the affected service type if there are more", ->
        NAME = "NAME"
        CONNTYPE = "PUSH_PULL"
        SVCTYPE1 = "DB_CONFIG"
        SVCTYPE2 = "GET_LOGS"
        ADDRESSES = ["address1", "address2"]
        ADDRESS_EMPTY = []
            
        Endpoints.onEndpoint NAME, SVCTYPE1, CONNTYPE, ADDRESSES
        Endpoints.onEndpoint NAME, SVCTYPE2, CONNTYPE, ADDRESSES
        Endpoints.onEndpoint NAME, SVCTYPE1, CONNTYPE, ADDRESS_EMPTY

        Endpoints._endpoints[NAME].should.not.have.property SVCTYPE1
        Endpoints._endpoints[NAME].should.have.property SVCTYPE2

    
    it "should modify the addresses if the endpoint already has existed", ->        
        NAME = "NAME"
        CONNTYPE = "REQ_REP"
        SVCTYPE = "DB_CONFIG"
        ADDRESSES = ["address1", "address2"]
        ADDRESSES2 = ["address5", "address3"]
            
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE, ADDRESSES
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE, ADDRESSES2
        
        Endpoints._endpoints.should.have.deep.property NAME
        Endpoints._endpoints[NAME].should.have.deep.property SVCTYPE
        Endpoints._endpoints[NAME][SVCTYPE].should.have.deep.property CONNTYPE, ADDRESSES2

    it "should return the whole list", ->
        EPS = "EPS"
        Endpoints._endpoints = EPS
        result = Endpoints.getCompleteEndpointList()
        result.should.be.deep.equal EPS

    it "should return the column addresses of the current provider", ->
        NAME = "NAME"
        CONNTYPE = "PUB_SUB"
        SVCTYPE = "COLUMN"
        ADDRESSES = ["address1", "address2"]
            
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE, ADDRESSES
        result = Endpoints.getColumnAddress NAME
        result.should.be.deep.equal ADDRESSES
    
    it "should return the metadata addresses of the current provider", ->
        NAME = "NAME"
        CONNTYPE = "REQ_REP"
        SVCTYPE = "META_DATA"
        ADDRESSES = ["address1", "address2"]
            
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE, ADDRESSES
        result = Endpoints.getMetadataAddress NAME
        result.should.be.deep.equal ADDRESSES
    
    it "should return the dbconfig addresses", ->
        NAME = "NAME"
        CONNTYPE = "PUSH_PULL"
        SVCTYPE = "DB_CONFIG"
        ADDRESSES = ["address1", "address2"]
            
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE, ADDRESSES
        result = Endpoints.getDbConfigAddress NAME
        result.should.be.deep.equal ADDRESSES
    
    it "should return the dbconfig query addresses", ->
        NAME = "NAME"
        CONNTYPE = "REQ_REP"
        SVCTYPE = "DB_CONFIG_QUERY"
        ADDRESSES = ["address1", "address2"]
            
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE, ADDRESSES
        result = Endpoints.getDbConfigQueryAddress NAME
        result.should.be.deep.equal ADDRESSES

    it "should return the log record addresses", ->
        ADDRESSES = ["address1", "address2"]
            
        Endpoints.onEndpoint Const.DIAG_SERVICE, Const.ENDPOINT_TYPE.LOG_RECORD, Const.SOCKET_TYPE.PUB_SUB, ADDRESSES
        result = Endpoints.getLogRecordAddress()
        result.should.be.deep.equal ADDRESSES
    
    it "should return the query addresses of the current provider", ->
        NAME = "NAME"
        CONNTYPE = "PUSH_PULL"
        SVCTYPE = "QUERY"
        ADDRESSES = ["address1", "address2"]
            
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE, ADDRESSES
        result = Endpoints.getQueryAddress NAME
        result.should.be.deep.equal ADDRESSES

    it "should return the config addresses of the current provider", ->
        NAME = Const.CONFIG_SERVICE
        CONNTYPE = "REQ_REP"
        SVCTYPE = "CONFIG"
        ADDRESSES = ["address1", "address2"]
            
        Endpoints.onEndpoint NAME, SVCTYPE, CONNTYPE, ADDRESSES
        result = Endpoints.getConfigServiceAddress()
        result.should.be.deep.equal ADDRESSES

    it "should return the list of data providers", ->
        DPS = ["dp1", "dp2"]
        OTHER = "OTHER"
        CONNTYPE = "PUSH_PULL"
        SVCTYPES = ["QUERY", "COLUMN", "META_DATA"]
        ADDRESSES = ["address1", "sesfssgs"]

        Endpoints.onEndpoint DPS[0], SVCTYPES[0], CONNTYPE, ADDRESSES
        Endpoints.onEndpoint DPS[0], SVCTYPES[1], CONNTYPE, ADDRESSES
        Endpoints.onEndpoint DPS[0], SVCTYPES[2], CONNTYPE, ADDRESSES
        Endpoints.onEndpoint DPS[1], SVCTYPES[0], CONNTYPE, ADDRESSES
        Endpoints.onEndpoint DPS[1], SVCTYPES[1], CONNTYPE, ADDRESSES
        Endpoints.onEndpoint DPS[1], SVCTYPES[2], CONNTYPE, ADDRESSES
        Endpoints.onEndpoint DPS[1], SVCTYPES[0], CONNTYPE, ADDRESSES
        Endpoints.onEndpoint OTHER, SVCTYPES[0], CONNTYPE, ADDRESSES

        provs = Endpoints.getDataProviders()
        provs.should.be.deep.equal DPS


        