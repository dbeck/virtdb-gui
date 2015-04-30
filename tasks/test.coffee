gulp = require 'gulp'
istanbul = require 'gulp-coffee-istanbul'
mocha = require 'gulp-mocha'

gulp.task 'test', ['compile-server-coffee'], ->
    gulp.src 'test/*.coffee',
        read: false
    .pipe mocha
        reporter: 'min'

gulp.task 'coverage', ->
    gulp.src ['src/scripts/**/*.coffee']
        .pipe istanbul
            includeUntested: true
        .pipe istanbul.hookRequire()
        .on 'finish', ->
            gulp.src ['test/*.coffee']
                .pipe mocha
                    reporter: 'spec'
                .pipe istanbul.writeReports
                    dir: '.'
                    reporters: ['cobertura']
