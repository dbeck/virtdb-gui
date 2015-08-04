config = require('./server/config')
VirtDBLoader = require('./server/virtdb_loader')
express = require('express')
path = require('path')
favicon = require('static-favicon')
logger = require('morgan')
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
fs = require('fs')
basicAuth = require('basic-auth')
EXPRESS_PORT = config.getCommandLineParameter('port')
LIVERELOAD_PORT = 35729
test = 'cica4'
app = module.exports.app = exports.app = express()

httpAuth = (req, res, next) ->

    unauthorized = (res) ->
        res.set 'WWW-Authenticate', 'Basic realm=Authorization Required'
        res.sendStatus 401

    user = basicAuth(req)
    if !user or !user.name or !user.pass
        return unauthorized(res)
    if user.name == authData.name and user.pass == authData.password
        next()
    else
        unauthorized res

try
    authData = JSON.parse(fs.readFileSync('auth.json').toString())
    app.use httpAuth
catch e
    console.log 'Missing local auth data'

allowCrossDomain = (req, res, next) ->
    # Uncomment to allow CORS
    #     res.header('Access-Control-Allow-Origin', '*');
    #     res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
    #     res.header('Access-Control-Allow-Headers', 'Content-Type');
    next()
    return

# Authentication
session = require('express-session')
app.use session(secret: 'keyboard cat')
auth = require('./server/authentication')
auth.initialize app
# Authentication end

app.use favicon()
app.use bodyParser.json()
app.use bodyParser.urlencoded()
app.use cookieParser()
app.use allowCrossDomain
app.use express.static(path.join(__dirname, 'static'))
if app.get('env') == 'development'
    app.use require('connect-livereload')(port: LIVERELOAD_PORT)
index = require('./server/index_route')
api = require('./server/api_route')
app.use '/api', api
app.use '/', index
VirtDBLoader.start (err) ->
    if err == null
        protocolString = ''
        protocol = null
        try
            options =
                key: fs.readFileSync('./ssl/server.key')
                cert: fs.readFileSync('./ssl/server.crt')
            protocol = require('https').createServer(options, app)
            protocolString = 'https'
        catch ex
            protocol = require('http').createServer(app)
            protocolString = 'http'
        server = protocol.listen(EXPRESS_PORT, ->
            console.log 'Listening on', protocolString, 'port', server.address().port
            return
        )
    else
        console.error 'Error while initializing VirtDB', err
    return

