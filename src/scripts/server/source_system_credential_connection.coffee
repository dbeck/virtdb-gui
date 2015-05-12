zmq = require 'zmq'
Const = (require "virtdb-connector").Const
log = (require "virtdb-connector").log
V_ = log.Variable
SecurityProto = (require "virtdb-proto").security
Endpoints = require "./endpoints"
require("source-map-support").install()

class SourceSystemCredentialConnection

    socket: null
    callback: null

    constructor: ->

    send: (message, callback) =>
        @_initSocket()
        @callback = callback
        try
            console.log message
            socketMessage = SecurityProto.serialize message, "virtdb.interface.pb.SourceSystemCredentialRequest"
            @socket.send socketMessage
        catch ex
            log.error "Problem during sending SourceSystemCredentialRequest message", V_(ex)
            @callback null

    _initSocket: =>
        try
            @socket = zmq.socket Const.ZMQ_REQ
            for addr in Endpoints.getSourceSystemCredentialAddress()
                @socket.connect addr
            @socket.on "message", @_onMessage
        catch ex
            log.error "Problem during initiating SourceSystemCredential socket", V_(ex)
            @callback null        

    _onMessage: (message) =>
        try 
            reply = SecurityProto.parse message, "virtdb.interface.pb.SourceSystemCredentialReply"
            @callback reply
        catch ex
            log.error "Problem during parsing SourceSystemCredentialReply", V_(ex)
            @callback null

module.exports = SourceSystemCredentialConnection
