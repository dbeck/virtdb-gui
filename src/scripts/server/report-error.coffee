log = (require "virtdb-connector").log
V_ = log.Variable

module.exports = (reply, callback) =>
        if not reply?
            err = new Error "Problem with socket communication"
            callback err, null
            return true
        if reply.Type is "ERROR_MSG"
            err = new Error reply.Err.Msg
            log.error "Service responded with error", V_(err)
            callback err, null
            return true
        return false