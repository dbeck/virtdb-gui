var config = require("./server/config")
var VirtDBLoader = require("./server/virtdb_loader")
var express = require('express');
var path = require('path');
var favicon = require('static-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var fs = require('fs');

var EXPRESS_PORT = config.getCommandLineParameter("port")
var LIVERELOAD_PORT = 35729;
var test = 'cica4';

var app = module.exports.app = exports.app = express();

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
auth.initalize(app);
// Authentication end 

// app.set('view engine', 'html');
// app.set('views', path.join(__dirname, 'static/pages'));

app.use(favicon());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded());
app.use(cookieParser());
app.use(allowCrossDomain);
app.use(express.static(path.join(__dirname, 'static')));
app.use(express.static(path.join(__dirname, 'static/pages')));

if (app.get('env') === 'development') {
    app.use(require('connect-livereload')({
    port: LIVERELOAD_PORT
  }));
}

var index = require('./server/index_route');
var api = require('./server/api_route');
app.use('/api', api);
app.use('/', index);

server = app.listen(EXPRESS_PORT, function() {
    console.log('Listening on port %d', server.address().port);
});
VirtDBLoader.start();
