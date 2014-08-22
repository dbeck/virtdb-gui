var gulp = require('gulp');
var coffee = require('gulp-coffee');
var spawn = require('child_process').spawn;
var sourcemaps = require('gulp-sourcemaps');
var wait = require('gulp-wait')
var browserSync = require('browser-sync');
var node;

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

// Reload all Browsers
gulp.task('browser-sync-reload', function () {
    browserSync.reload();
});

// Start the server
gulp.task('browser-sync', function() {
    browserSync.init(null, {
  		proxy: {
  			host: "http://localhost",
  			port: "3000"
  		}
	});
});

gulp.task('watch', function()
{
    //Client side watch
    gulp.watch(['views/*.jade'], ['browser-sync-reload']);
    gulp.watch(['public/stylesheets/*.styl'], ['browser-sync-reload']);
    gulp.watch(['public/javascripts/*.coffee'], ['client-side-coffee', 'browser-sync-reload']);

    //Server side watch
    gulp.watch(['logic/*.coffee'], ['server-side-coffee']);
});

gulp.task('default', ['browser-sync', 'watch']);
