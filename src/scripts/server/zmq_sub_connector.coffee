zmq = require "zmq"
fs = require "fs"
VirtDB = require "virtdb-connector"
Const = VirtDB.Const
log = VirtDB.log
V_ = log.Variable
lz4 = require "lz4"
QueryIdGenerator = require "./query_id_generator"

DataProto = (require "virtdb-proto").data
CommonProto = (require "virtdb-proto").common

ZmqSubConnector =
    connectToFirstAvailable: (zmqSocket, addresses) ->
        for addr in addresses
            try
                zmqSocket.connect addr
                # Only go for the first successful connection for this specific provider.
                return addr
            catch ex
                log.warn "Failed to initiate column socket for:", V_(addr)
        throw new Error "Failed to connect any of the column addresses!"

module.exports = ZmqSubConnector
