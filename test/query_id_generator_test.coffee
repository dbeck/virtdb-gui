idGen = require "../src/scripts/server/query_id_generator"

chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");

chai.use sinonChai

describe "QueryIdGenerator", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()

    afterEach =>
        sandbox.restore()

    it "should get new IDs incrementally until the MAX ID value, then start it over", ->
        # Let's make the test not run too long
        idGen.MAX_QUERY_ID = 100

        for i in [0..idGen.MAX_QUERY_ID - 1]
            idGen.getNextQueryId().should.equal i.toString()

        idGen.getNextQueryId().should.equal "0"
        idGen.getNextQueryId().should.equal "1"
        idGen.getNextQueryId().should.equal "2"
