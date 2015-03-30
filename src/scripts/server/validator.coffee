VirtDBConnector = require "virtdb-connector"
log = VirtDBConnector.log
V_ = log.Variable

module.exports = (path, params) ->
    return (req, res, next) ->
        try
            for param of params
                if params[param].required and not req.body[param]?
                    throw new Error("Missing required parameter: #{param}")
                if params[param].validate? and not params[param].validate req.body[param]
                    throw new Error("Invalid parameter: #{param}")
            next()
        catch ex
            log.error "Endpoint called with bad parameters", V_(path), V_(ex)
            res.status(400).send()

