ColumnReceiver = require "../src/scripts/server/column_receiver"
VirtdbConnector = require "virtdb-connector"
FieldData = VirtdbConnector.FieldData

chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");
chai.use sinonChai

describe "ColumnReceiver", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()

    afterEach =>
        sandbox.restore()

    it "should collect the columns and get it back when they are all received and the order of columns was ok", ->
        fields = [
            Name: "FIELD1"
        ,
            Name: "FIELD2"
        ,
            Name: "FIELD3"
        ,
            Name: "FIELD4"
        ]
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
        fields = [
            Name: "FIELD1"
        ,
            Name: "FIELD2"
        ,
            Name: "FIELD3"
        ,
            Name: "FIELD4"
        ]
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
        cr.add data[3]
        cr.add data[1]
        cr.add data[2]
        cr.add data[0]

        readyCallback.should.have.been.calledWith expected






