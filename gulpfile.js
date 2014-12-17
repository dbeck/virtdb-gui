var gulp = require('gulp');
var coffee = require('gulp-coffee');
var sourcemaps = require('gulp-sourcemaps');
var jade = require('gulp-jade');
var stylus = require('gulp-stylus');
var mainBowerFiles = require('main-bower-files');
var server = require('gulp-express');
var mocha = require('gulp-mocha');
require('coffee-script/register')

var EXPRESS_ROOT = __dirname;
var LIVERELOAD_PORT = 3001;
var NOT_LIVERELOAD_PORT = 3002;

var lr;

gulp.task('start-livereload-server', function() {
  lr = require('tiny-lr')();
  lr.listen(LIVERELOAD_PORT);
});

function notifyLivereload(event) {
  var fileName = require('path').relative(EXPRESS_ROOT, event.path);
  lr.changed({
    body: {
      files: [fileName]
    }
  });
}

function startExpress() {
    server.run({
        file: 'app.js',
        env: 'development',
        port: NOT_LIVERELOAD_PORT
    });
}

gulp.task('compile-stylus', function() {
    gulp.src('./src/styles/*.styl')
        .pipe(stylus())
        .pipe(gulp.dest('./static/styles'));
    gulp.src('./src/styles/*.css')
        .pipe(gulp.dest('./static/styles'));
})

gulp.task('compile-jade', function() {
    gulp.src(['./src/pages/*.jade', '!./src/pages/index.jade'])
        .pipe(jade({pretty: true}))
        .pipe(gulp.dest('./static/pages'));
})

gulp.task('copy-index-to-static', function(){
    gulp.src('./src/pages/index.jade')
        .pipe(gulp.dest('./static/pages'));
});

gulp.task('copy-images', function(){
    gulp.src(['./src/images/*.png', './src/images/*.jpg'])
        .pipe(gulp.dest('./static/images'));
});

gulp.task('compile-client-coffee', function() {
    var sources = './src/scripts/client/*.coffee';
    var destDir = './static/scripts/';
    gulp.src(sources)
        .pipe(coffee({bare: true}).on('error', console.error))
        .pipe(gulp.dest(destDir))
});

gulp.task('compile-server-coffee', function() {
    var sources = './src/scripts/server/*.coffee';
    var destDir = './server';
    gulp.src(sources)
        .pipe(sourcemaps.init())
        .pipe(coffee({bare: true}).on('error', console.error))
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest(destDir))
})

gulp.task('start-dev-server', ['prepare-files','start-livereload-server'], startExpress)

gulp.task('restart-express', ['compile-server-coffee'], startExpress)

gulp.task('prepare-files', [
    'collect-libs',
    'compile-server-coffee',
    'copy-index-to-static',
    'copy-images',
    'compile-client-coffee',
    'compile-jade',
    'compile-stylus',
    ],
    function () {
        console.log("Prepare files...");
    }
)

gulp.task('collect-libs', function() {
    var destDir = 'static/libs';

    var files = mainBowerFiles();
    gulp.src(files)
        .pipe(gulp.dest(destDir));

    var bootstrap_js = [
        "bower_components/bootstrap/js/collapse.js",
        "bower_components/bootstrap/js/transition.js",
        "bower_components/bootstrap/js/alert.js"
    ];
    gulp.src(bootstrap_js)
        .pipe(gulp.dest(destDir))
});

gulp.task('watch', function()
{
    //Reloader watch
    gulp.watch(['static/**/*.*'], notifyLivereload);

    //Client side watch
    gulp.watch(['src/pages/**/*.jade'], ['compile-jade']);
    gulp.watch(['src/styles/**/*.styl', 'src/styles/**/*.css'], ['compile-stylus']);
    gulp.watch(['src/scripts/client/**/*.coffee'], ['compile-client-coffee']);
    gulp.watch(['src/pages/index.jade'], ['copy-index-to-static']);
    gulp.watch(['src/images/*.png', 'src/images/*.jpg'], ['copy-images']);

    //Server side watch
    gulp.watch(['src/scripts/server/**/*.coffee'], ['restart-express']);

    //Third-party watch
    gulp.watch(['bower.json'], ['collect-libs']);
});

gulp.task('test', ['compile-server-coffee'], function ()
{
    return gulp.src('test/*.coffee', {read: false})
    .pipe(mocha({reporter: 'min'}));
})

gulp.task('default', [
    'watch',
    'start-dev-server',
]);
