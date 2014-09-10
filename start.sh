#!/bin/bash

npm install
node_modules/bower/bin/bower install --config.interactive=false
cd proto
gyp --depth=. proto.gyp
make
cd ..
node_modules/gulp/bin/gulp.js
