var config = require("./server/config") 
var VirtDBLoader = require("./server/virtdb_loader")
var express = require('express');
var path = require('path');
var favicon = require('static-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var fs = require('fs');
var basicAuth = require('basic-auth');

var EXPRESS_PORT = config.getCommandLineParameter("port")
var LIVERELOAD_PORT = 35729;
var test = 'cica4';

var app = module.exports.app = exports.app = express();

var httpAuth = function (req, res, next) {
    function unauthorized(res) {
        res.set('WWW-Authenticate', 'Basic realm=Authorization Required');
        return res.sendStatus(401);
    };

    var user = basicAuth(req);

    if (!user || !user.name || !user.pass) {
        return unauthorized(res);
    }
    if (user.name === authData.name && user.pass === authData.password) {
        return next();
    } else {
        return unauthorized(res);
    };
}
try {
    var authData = JSON.parse(fs.readFileSync("auth.json").toString());
    app.use(httpAuth);
} catch(e) {
    console.log("Missing local auth data");
}

var allowCrossDomain = function(req, res, next) {
// Uncomment to allow CORS
//     res.header('Access-Control-Allow-Origin', '*');
//     res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
//     res.header('Access-Control-Allow-Headers', 'Content-Type');

    next();
}

// Authentication
var session = require('express-session')
app.use(session({secret: 'keyboard cat'}));
var auth = require('./server/authentication');
auth.initialize(app);
// Authentication end 

// app.set('view engine', 'html');
// app.set('views', path.join(__dirname, 'static/pages'));

app.use(favicon());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded());
app.use(cookieParser());
app.use(allowCrossDomain);
app.use(express.static(path.join(__dirname, 'static')));

if (app.get('env') === 'development') {
    app.use(require('connect-livereload')({
    port: LIVERELOAD_PORT
  }));
}

var index = require('./server/index_route');
var api = require('./server/api_route');
app.use('/api', api);
app.use('/', index);

VirtDBLoader.start(function(err) {
    if (err == null) {
        var http = require('http').Server(app);

        var server = http.listen(EXPRESS_PORT, function() {
            console.log('Listening on port %d', server.address().port);
        });
    }
    else {
        console.error('Error while initializing VirtDB', err);
    }
});
