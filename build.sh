#!/bin/bash

RELEASE_PATH="release"

function release {
  echo "Creating release"
  VERSION=`npm version patch`
  git add package.json
  git commit -m "Increased version number to $VERSION"
  mkdir -p $RELEASE_PATH
  cp --parents common/proto/*.desc $RELEASE_PATH
  cp -R static $RELEASE_PATH
  cp -R server $RELEASE_PATH
  cp -R node_modules $RELEASE_PATH
  cp app.js $RELEASE_PATH
  mkdir -p $RELEASE_PATH/lib
  cp /usr/lib64/libzmq.so.3 $RELEASE_PATH/lib
  cp /usr/local/lib/libprotobuf.so.9 $RELEASE_PATH/lib
  tar -czvf virtdb-gui-$VERSION.tar.gz -C $RELEASE_PATH .
}

function clear_gui {
  echo "clearing gui"
  rm -rf node_modules
  rm -rf src/out
  rm -rf static
  rm -rf bower_components
}

[[ ${1,,} == "release" ]] && RELEASE=true || RELEASE=false

echo "building gui"
[[ $RELEASE == true ]] && clear_gui
npm install
node_modules/bower/bin/bower --allow-root install
node_modules/gulp/bin/gulp.js prepare-files

echo "start tests"
export JUNIT_REPORT_PATH=test_report.xml
export JUNIT_REPORT_STACK=1
./node_modules/.bin/mocha --compilers=coffee:coffee-script/register --reporter mocha-jenkins-reporter test/*.coffee

[[ $RELEASE == true ]] && release || echo "non-release"
