sinon = require "sinon"

class SocketStub
    receive: null
    isBound: false
    setsockopt: null
    sentData: null
    send: null
    constructor: ->
        @setsockopt = sinon.spy()
        @sentData = []
        @send = sinon.spy((data) =>
            @sentData.push data
        )
    on: (message, @receive) =>
    connect: (address) =>
    bind: (address, callback) =>
        @isBound = true
        callback()
    close: () =>

module.exports = SocketStub
