gulp = require 'gulp'
require 'coffee-script/register'

test = require './tasks/test.coffee'
client = require './tasks/client.coffee'
server = require './tasks/server.coffee'
dev = require './tasks/dev.coffee'

gulp.task 'build', ['client-build', 'server-build']

# Both will be deprecated and replace by the build task when that is introduced to all projects
gulp.task 'prepare-files', ['client-build', 'server-build']
gulp.task 'coffee', ['prepare-files']

gulp.task 'default', [
    'watch',
    'prepare-files',
    'serve'
]
