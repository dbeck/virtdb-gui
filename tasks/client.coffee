args = (require 'nomnom').parse()
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
    gulp.src ['./src/pages/*.jade']
        .pipe jade
            pretty: true
        .pipe gulp.dest './static/pages'

#gulp.task 'copy-index-to-static', ->
#    gulp.src ['./src/pages/index.jade', './src/pages/login.jade']
#        .pipe gulp.dest './static/pages'
#
gulp.task 'copy-images', ->
    gulp.src ['./src/images/*.png', './src/images/*.jpg']
        .pipe gulp.dest './static/images'

compileCoffee = (src, dest) ->
    gulp.src src
        .pipe sourcemaps.init()
        .pipe coffee
            bare: true
        .on 'error', console.error
        .pipe sourcemaps.write '.'
        .pipe gulp.dest dest

gulp.task 'compile-client-production', ->
    compileCoffee './src/scripts/client/*.coffee', './static/scripts'

gulp.task 'compile-client-dev', ['compile-client-production'], ->
    if args.offline
        compileCoffee './src/scripts/client/dev/*.coffee', './static/scripts'

gulp.task 'compile-client-coffee', ['compile-client-dev']

gulp.task 'bower-install', ->
    bower()

gulp.task 'collect-libs', ['bower-install'], ->
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
    gulp.watch ['src/scripts/client/**/*.coffee'], ['browserify']
    gulp.watch ['src/images/*.png', 'src/images/*.jpg'], ['copy-images']

gulp.task 'client-build',
    [
        'collect-libs'
        #        'copy-index-to-static'
        'copy-images'
        'compile-client-coffee'
        'compile-jade'
        'compile-stylus'
        'browserify'
    ]
