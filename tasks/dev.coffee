gulp = require 'gulp'
gls = require 'gulp-live-server'

EXPRESS_ROOT = __dirname
LIVERELOAD_PORT = 3001
NOT_LIVERELOAD_PORT = 3002

server = null

gulp.task 'serve', ->
    console.log "Starting serve"
    server = gls.new ['app.js', '-s', 'tcp://127.0.0.1:12345']
    server.start()
    console.log "Finished serve"

notifyLivereload = (event) ->
    fileName = require('path').relative EXPRESS_ROOT, event.path
    lr.changed
        body:
            files: [fileName]

testWatch = (args...) ->
    console.log args

gulp.task 'update-server', ['compile-server-coffee'], ->
    console.log server
    server?.start()
    console.log "Server started."

gulp.task 'watch', ['client-watch', 'server-watch', 'serve'], ->
    console.log "Starting watches"
    gulp.watch ['static/**/*', 'static/**/**/*'], server.notify
    gulp.watch ['app.js'], server.start

