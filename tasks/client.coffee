gulp = require 'gulp'
stylus = require 'gulp-stylus'
jade = require 'gulp-jade'
coffee = require 'gulp-coffee'
sourcemaps = require 'gulp-sourcemaps'
bower = require 'gulp-bower'
mainBowerFiles = require 'main-bower-files'
browserify = require 'browserify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'

gulp.task 'compile-stylus', ->
    gulp.src './src/styles/*.styl'
        .pipe stylus()
        .pipe gulp.dest './static/styles'
    gulp.src './src/styles/*.css'
        .pipe gulp.dest './static/styles'
    gulp.src './src/styles/fonts/*'
        .pipe gulp.dest './static/fonts'

gulp.task 'compile-jade', ->
    gulp.src ['./src/pages/*.jade', '!./src/pages/index.jade', '!./src/pages/login.jade']
        .pipe jade
            pretty: true
        .pipe gulp.dest './static/pages'

gulp.task 'copy-index-to-static', ->
    gulp.src ['./src/pages/index.jade', './src/pages/login.jade']
        .pipe gulp.dest './static/pages'

gulp.task 'copy-images', ->
    gulp.src ['./src/images/*.png', './src/images/*.jpg']
        .pipe gulp.dest './static/images'

gulp.task 'compile-client-coffee', ->
    gulp.src './src/scripts/client/*.coffee'
        .pipe sourcemaps.init()
        .pipe coffee
            bare: true
        .on 'error', console.error
        .pipe sourcemaps.write '.'
        .pipe gulp.dest './static/scripts/'

gulp.task 'collect-libs', ->
    bower()
    destDir =
    gulp.src mainBowerFiles()
        .pipe gulp.dest 'static/libs'

    bootstrap_js = [
        "bower_components/bootstrap/js/collapse.js"
        "bower_components/bootstrap/js/transition.js"
        "bower_components/bootstrap/js/alert.js"
    ]
    gulp.src bootstrap_js
        .pipe gulp.dest 'static/libs'

gulp.task 'browserify', ['compile-client-coffee'], ->
    b = browserify
        entries: './static/scripts/virtdb.js'
        debug: true
    b.bundle()
        .pipe source 'virtdb.js'
        .pipe buffer()
        .pipe gulp.dest 'static/scripts/dist'

gulp.task 'client-watch', ->
    gulp.watch ['src/pages/**/*.jade'], ['compile-jade']
    gulp.watch ['src/styles/**/*.styl', 'src/styles/**/*.css'], ['compile-stylus']
    gulp.watch ['src/scripts/client/**/*.coffee'], ['compile-client-coffee']
    gulp.watch ['src/pages/index.jade'], ['copy-index-to-static']
    gulp.watch ['src/images/*.png', 'src/images/*.jpg'], ['copy-images']

gulp.task 'client-build',
    [
        'collect-libs'
        'copy-index-to-static'
        'copy-images'
        'compile-client-coffee'
        'compile-jade'
        'compile-stylus'
        'browserify'
    ]
