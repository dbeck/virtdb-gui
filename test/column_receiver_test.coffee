ColumnReceiver = require "../src/scripts/server/column_receiver"
VirtdbConnector = require "virtdb-connector"
FieldData = VirtdbConnector.FieldData

chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require "sinon-chai"
chai.use sinonChai

describe "ColumnReceiver", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()

    afterEach =>
        sandbox.restore()

    it "should collect the columns and get it back when they are all received and the order of columns was ok", ->
        fields = ["FIELD1", "FIELD2", "FIELD3", "FIELD4"]
        data = [
            Name: "FIELD1"
            Data: "DATA1"
            EndOfData: true
        ,
            Name: "FIELD2"
            Data: "DATA2"
            EndOfData: true
        ,
            Name: "FIELD3"
            Data: "DATA3"
            EndOfData: true
        ,
            Name: "FIELD4"
            Data: "DATA4"
            EndOfData: true
        ]
        expected = [
            Name: "FIELD1"
            Data: "DATA1"
        ,
            Name: "FIELD2"
            Data: "DATA2"
        ,
            Name: "FIELD3"
            Data: "DATA3"
        ,
            Name: "FIELD4"
            Data: "DATA4"
        ]

        readyCallback = sinon.spy()
        fieldDataGet = sandbox.stub FieldData, "get"
        for d in data
            fieldDataGet.withArgs(d).returns d.Data

        cr = new ColumnReceiver readyCallback, fields
        for col in data
            cr.add col

        readyCallback.should.have.been.calledWith expected

    it "should collect the columns and get it back when they are all received and the order of columns was random", ->
        fields = ["FIELD1", "FIELD2", "FIELD3", "FIELD4"]
        data = [
            Name: "FIELD1"
            Data: "DATA1"
            EndOfData: true
        ,
            Name: "FIELD2"
            Data: "DATA2"
            EndOfData: true
        ,
            Name: "FIELD3"
            Data: "DATA3"
            EndOfData: true
        ,
            Name: "FIELD4"
            Data: "DATA4"
            EndOfData: true
        ]
        expected = [
            Name: "FIELD1"
            Data: "DATA1"
        ,
            Name: "FIELD2"
            Data: "DATA2"
        ,
            Name: "FIELD3"
            Data: "DATA3"
        ,
            Name: "FIELD4"
            Data: "DATA4"
        ]

        readyCallback = sandbox.spy()
        fieldDataGet = sandbox.stub FieldData, "get"
        for d in data
            fieldDataGet.withArgs(d).returns d.Data

        cr = new ColumnReceiver readyCallback, fields
        cr.add data[3]
        cr.add data[1]
        cr.add data[2]
        cr.add data[0]

        readyCallback.should.have.been.calledWith expected


    it "should log warning if data arrives on a column after end of data, and drop that unexpected data", ->
        fields = ["FIELD1", "FIELD2"]
        data = [
            Name: "FIELD1"
            Data: "DATA1"
            EndOfData: true
        ,
            Name: "FIELD2"
            Data: "DATA2"
            EndOfData: true
        ]
        expected = [
            Name: "FIELD1"
            Data: "DATA1"
        ,
            Name: "FIELD2"
            Data: "DATA2"
        ]

        readyCallback = sandbox.spy()
        fieldDataGet = sandbox.stub FieldData, "get"
        for d in data
            fieldDataGet.withArgs(d).returns d.Data
        logWarn = sandbox.stub VirtdbConnector.log, "warn"

        cr = new ColumnReceiver readyCallback, fields
        cr.add data[0]
        cr.add data[0]
        cr.add data[1]

        readyCallback.should.have.been.calledOnce
        readyCallback.should.have.been.calledWith expected
        logWarn.should.have.been.calledOnce


    it "should append incoming data to the existing, if data arrives to the same column for multiple times", ->
        fields = ["FIELD1", "FIELD2"]
        data = [
            Name: "FIELD1"
            Data: "You"
            EndOfData: false
        ,
            Name: "FIELD2"
            Data: "DATA2"
            EndOfData: true
        ,
            Name: "FIELD1"
            Data: "All"
            EndOfData: false
        ,
            Name: "FIELD1"
            Data: "Rock"
            EndOfData: true
        ]
        expected = [
            Name: "FIELD1"
            Data: "YouAllRock"
        ,
            Name: "FIELD2"
            Data: "DATA2"
        ]

        readyCallback = sandbox.spy()
        fieldDataGet = sandbox.stub FieldData, "get"
        cr = new ColumnReceiver readyCallback, fields
        for d in data
            fieldDataGet.withArgs(d).returns d.Data
            cr.add d

        readyCallback.should.have.been.calledOnce
        readyCallback.should.have.been.calledWith expected


    it "should not signal completion if not all the fields received end of data", ->
        fields = ["FIELD1", "FIELD2"]
        data = [
            Name: "FIELD1"
            Data: "DATA1"
            EndOfData: false
        ,
            Name: "FIELD1"
            Data: "DATA1"
            EndOfData: true
        ,
            Name: "FIELD2"
            Data: "DATA2"
            EndOfData: false
        ]

        readyCallback = sandbox.spy()
        fieldDataGet = sandbox.stub FieldData, "get"
        cr = new ColumnReceiver readyCallback, fields
        for d in data
            fieldDataGet.withArgs(d).returns d.Data
            cr.add d

        readyCallback.should.have.not.been.called


    it "should not signal completion if there is missing data for any field", ->
        fields = ["FIELD1", "FIELD2", "FIELD3"]
        data = [
            Name: "FIELD1"
            Data: "DATA1"
            EndOfData: false
        ,
            Name: "FIELD1"
            Data: "DATA1"
            EndOfData: true
        ,
            Name: "FIELD3"
            Data: "DATA3"
            EndOfData: true
        ]

        readyCallback = sandbox.spy()
        fieldDataGet = sandbox.stub FieldData, "get"
        cr = new ColumnReceiver readyCallback, fields
        for d in data
            fieldDataGet.withArgs(d).returns d.Data
            cr.add d

        readyCallback.should.have.not.been.called
