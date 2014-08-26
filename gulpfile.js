var gulp = require('gulp');
var coffee = require('gulp-coffee');
var spawn = require('child_process').spawn;
var sourcemaps = require('gulp-sourcemaps');
var wait = require('gulp-wait')
var nodemon = require('gulp-nodemon');
var node;
var lr;

var EXPRESS_ROOT = __dirname;
var LIVERELOAD_PORT = 3001;

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

gulp.task('client-side-coffee', function() {
    var scriptDir = './public/javascripts/';
    gulp.src(scriptDir + '*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee({bare: true}))
        .pipe(sourcemaps.write(scriptDir))
        .pipe(gulp.dest(scriptDir))
});

gulp.task('server-side-coffee', function() {
    gulp.src('logic/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee({bare: true}))
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest('logic'))
});

gulp.task('start-dev-server', function () {
    nodemon({
        script: './bin/www',
        watch: './logic',
        ext: 'coffee',
        legacyWatch: true,
        env: { 'NODE_ENV': 'development' }
    })
    .on('change', function () {
        gulp.start('server-side-coffee');
    })
    .on('restart', function () {
        console.log('Express server restarted!')
    });
})

gulp.task('watch', function()
{
    //Client side watch
    gulp.watch(['views/*.jade'], notifyLivereload);
    gulp.watch(['public/stylesheets/*.styl'], notifyLivereload);
    gulp.watch(['public/javascripts/*.js'], notifyLivereload);
    gulp.watch(['public/javascripts/*.coffee'], ['client-side-coffee']);
});

gulp.task('default', [
    'server-side-coffee',
    'client-side-coffee',
    'watch',
    'start-dev-server',
    'start-livereload-server',
]);
