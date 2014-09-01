var express = require('express');
var path = require('path');
var favicon = require('static-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');

var index = require('./src/scripts/server/out/index_route');
var api = require('./src/scripts/server/out/api_route');

var app = express();

app.set('view engine', 'jade');
app.set('views', path.join(__dirname, 'static/pages'));

app.use(favicon());
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded());
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'static')));

if (app.get('env') === 'development') {
    app.use(require('connect-livereload')({
    port: 3001
  }));
}

app.use('/api', api);
app.use('/', index);

module.exports = app;
