VirtDB = require "virtdb-connector"
log = VirtDB.log
V_ = log.Variable

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
