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
    clock = null

    beforeEach =>
        clock = sinon.useFakeTimers()
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDBConnector.log, "info"
        sandbox.stub VirtDBConnector.log, "debug"
        sandbox.stub VirtDBConnector.log, "trace"
        sandbox.stub VirtDBConnector.log, "error"
        clock.tick 100

    afterEach =>
        sandbox.restore()
        clock.restore()
        CacheHandler._reset()

    it "should store the data and give it back if we get it before ttl", ->
        CacheHandler._cacheTTL = 1

        DATA = "data"
        KEY = "key"
        OBJ = {}
        OBJ[KEY] = DATA

        CacheHandler.set KEY, DATA
        clock.tick 800
        result = CacheHandler.get KEY
        result.should.be.deep.equal DATA

    it "should store an array and give it back if we get it before ttl", ->
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
        clock.tick 200
        result = CacheHandler.get KEY
        result.should.deep.equal DATA

    it "should store large data and give it back if we get it before ttl", ->
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
        clock.tick 200
        result = CacheHandler.get KEY
        result.should.deep.equal DATA

    it "should return null if data requested after ttl", ->
        CacheHandler._cacheTTL = 1

        DATA = "data"
        KEY = "key"

        CacheHandler.set KEY, DATA
        clock.tick 1500
        result = CacheHandler.get KEY
        should.not.exist result


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

    it "should call the key expiration listeners if there are some", ->
        expListener1 = sandbox.spy()
        expListener2 = sandbox.spy()
        KEY1 = "KEY1"
        CacheHandler.addKeyExpirationListener KEY1, expListener1
        CacheHandler.addKeyExpirationListener KEY1, expListener2
        CacheHandler._onKeyExpired KEY1

        expListener1.should.have.been.calledOnce
        expListener2.should.have.been.calledOnce

    it "should not crash when there are no any listener to key and it was expired", ->
        KEY1 = "KEY1"
        CacheHandler._onKeyExpired KEY1

    it "should delete key expiration listeners after they have been", ->
        expListener1 = sandbox.spy()
        expListener2 = sandbox.spy()
        KEY1 = "KEY1"
        CacheHandler.addKeyExpirationListener KEY1, expListener1
        CacheHandler.addKeyExpirationListener KEY1, expListener2
        CacheHandler._onKeyExpired KEY1

        should.not.exist CacheHandler._keyExpirationListeners[KEY1]

    it "should list the stored keys", ->
        CacheHandler._cacheTTL = 1

        DATA = "data"
        KEY1 = "key1"
        KEY2 = "key2"

        CacheHandler.set KEY1, DATA
        CacheHandler.set KEY2, DATA
        clock.tick 300
        keys = CacheHandler.listKeys()
        keys.should.be.deep.equal [KEY1, KEY2]

    it "should delete the entry", ->
        CacheHandler._cacheTTL = 1

        DATA = "data"
        KEY = "key"

        CacheHandler.set KEY, DATA
        CacheHandler.delete KEY
        result = CacheHandler.get KEY
        should.not.exist result

