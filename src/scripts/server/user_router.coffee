router = require './router'
UserManager = require './user_manager'

router.get "/"
#, timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    res.json req.user

router.put "/:name", (req, res, err) =>
    UserManager.updateUser req.params.name, req.body.password, req.body.isAdmin, req.user.token, (err, data) =>
        if err?
            res.status(500).send()
        else
            res.status(200).send()

router.post "/", (req, res, err) =>
    UserManager.createUser req.body.name, req.body.password, req.body.isAdmin, req.user.token, (err, data) =>
        if err?
            res.status(500).send()
        else
            res.status(200).send()

router.delete "/:name", (req, res, err) =>
    UserManager.deleteUser req.params.name, req.user.token, (err, data) =>
        if err?
            res.status(500).send()
        else
            res.status(200).send()

router.get "/list", (req, res, err) =>
    UserManager.listUsers req.user.token, (err, users) =>
        if err?
            res.status(500).send()
        else if users?
            res.status(200).send users
        else
            res.status(500).send()

module.exports = router