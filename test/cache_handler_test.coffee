require("source-map-support").install()
NodeCache = require "node-cache"
Config = require "../src/scripts/server/config"
CacheHandler = require "../src/scripts/server/cache_handler"
VirtDBConnector = require "virtdb-connector"
log = VirtDBConnector.log

chai = require "chai"
expect = chai.expect
should = chai.should()
sinon = require "sinon"
sinonChai = require("sinon-chai");
chai.use sinonChai

describe "CacheHandler", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDBConnector.log, "info"
        sandbox.stub VirtDBConnector.log, "debug"
        sandbox.stub VirtDBConnector.log, "trace"
        sandbox.stub VirtDBConnector.log, "error"

    afterEach =>
        sandbox.restore()
        CacheHandler._reset()

    it "should store the data and give it back if we get it before ttl", (done) ->
        this.timeout(1200)
        CacheHandler._cacheTTL = 1

        DATA = "data"
        KEY = "key"
        OBJ = {}
        OBJ[KEY] = DATA

        CacheHandler.set KEY, DATA
        setTimeout () ->
            result = CacheHandler.get KEY
            result.should.be.deep.equal DATA
            done()
        , 800

    it "should store an array and give it back if we get it before ttl", (done) ->
        this.timeout(1200)
        CacheHandler._cacheTTL = 1

        DATA = {
            Tables: [
                Name: 'BSEG'
                Comments: []
                Properties: []
                Fields: [
                    Name: "MANDT"
                    Desc:
                        Type: "INT32"
                    Comments: [
                        Text: 'Client'
                        Language: 'EN'
                    ]
                    Properties: [
                        Key: 'fieldname'
                        Children: []
                        Value:
                            Type: 'STRING'
                            StringValue: 'MANDT'
                    ,
                        Key: 'position'
                        Children: []
                        Value:
                            Type: 'STRING'
                            Value: '0'
                    ]
                ]
            ]
        }
        KEY = "sap_{\"Name\":\"BSEG\",\"WithFields\":true}"
        OBJ = {}
        OBJ[KEY] = DATA

        CacheHandler.set KEY, DATA
        setTimeout () ->
            result = CacheHandler.get KEY
            result.should.deep.equal DATA
            done()
        , 100

    it "should store large data and give it back if we get it before ttl", () ->
        CacheHandler._cacheTTL = 1

        DATA =
            Tables: []

        for i in [0..4]
            table = {}
            table.Name = "table #{i}"
            table.Fields = []
            for fieldIndex in [0..400]
                field = {}
                field.Name = "field#{table.Name}#{fieldIndex}"
                table.Fields.push field
            DATA.Tables.push table

        KEY = "key"
        OBJ = {}
        OBJ[KEY] = DATA

        CacheHandler.set KEY, DATA
        result = CacheHandler.get KEY
        result.should.deep.equal DATA

    it "should return null if data requested after ttl", (done) ->
        this.timeout(1500)
        CacheHandler._cacheTTL = 1

        DATA = "data"
        KEY = "key"

        CacheHandler.set KEY, DATA
        setTimeout () ->
            result = CacheHandler.get KEY
            should.not.exist result
            done()
        , 1300


    it "should save new ttl value and create new cache", ->
        TTL = 42

        ccStub = sandbox.stub CacheHandler, "_createCache"

        CacheHandler._cache =
            on: sinon.spy()
            _killCheckPeriod: sinon.spy()

        CacheHandler._onNewCacheTTL TTL

        CacheHandler._cacheTTL.should.be.deep.equal TTL
        ccStub.should.have.been.calledOnce

    it "should use the saved parameters when requesting new cache instance: both provided", () ->
        CP = 43
        TTL = 42

        (sandbox.stub Config, "getCommandLineParameter").returns 43
        CacheHandler._cacheTTL = TTL
        cache =
            on: sinon.spy()
            _killCheckPeriod: sinon.spy()

        EXP_OPTIONS =
            checkperiod: CP
            stdTTL: TTL

        getCacheInstanceStub = sandbox.stub CacheHandler, "_getCacheInstance"
        getCacheInstanceStub.returns cache

        CacheHandler._createCache()

        getCacheInstanceStub.should.have.been.calledOnce
        getCacheInstanceStub.should.have.been.calledWithExactly EXP_OPTIONS


    it "should use the saved parameters when requesting new cache instance: only checkperiod provided", () ->
        CP = 43
        (sandbox.stub Config, "getCommandLineParameter").returns CP

        cache =
            on: sinon.spy()
            _killCheckPeriod: sinon.spy()

        EXP_OPTIONS =
            checkperiod: CP

        getCacheInstanceStub = sandbox.stub CacheHandler, "_getCacheInstance"
        getCacheInstanceStub.returns cache

        CacheHandler._createCache()

        getCacheInstanceStub.should.have.been.calledOnce
        getCacheInstanceStub.should.have.been.calledWithExactly EXP_OPTIONS

    it "should register for the parameter changes to the config", ->
        addCfgListStub = sandbox.stub Config, "addConfigListener"

        CacheHandler.init()

        addCfgListStub.should.have.been.calledWithExactly Config.CACHE_TTL, CacheHandler._onNewCacheTTL
