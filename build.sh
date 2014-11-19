#!/bin/bash
NODE_CONNECTOR_PATH="common/node-connector"
RELEASE_PATH="release"
BUILD_NUMBER=${2}

function release {
  echo "Creating release"
  mkdir -p $RELEASE_PATH
  cp --parents -R src/scripts/server/out $RELEASE_PATH
  cp --parents common/proto/*.desc $RELEASE_PATH
  cp -R static $RELEASE_PATH
  cp app.js $RELEASE_PATH
  mkdir -p $RELEASE_PATH/lib
  cp /usr/lib64/libzmq.so.3 $RELEASE_PATH/lib 
  cp /usr/local/lib/libprotobuf.so.9 $RELEASE_PATH/lib
  tar -czvf virtdb-gui-$BUILD_NUMBER.tar.gz -C $RELEASE_PATH .
}

function clear_connector {
  echo "clearining node connector"
  rm -rf $NODE_CONNECTOR_PATH/node_modules
  rm -rf $NODE_CONNECTOR_PATH/lib
}

function clear_gui {
  echo "Clearing gui"
  rm -rf node_modules
  rm -rf src/out
  rm -rf static
  rm -rf bower_components
}

[[ ${1,,} == "release" ]] && RELEASE=true || RELEASE=false

git submodule update --init --recursive
pushd common/proto
gyp --depth=. proto.gyp
make
popd

echo "Building node-connector"
[[ $RELEASE == true ]] && clear_connector
pushd $NODE_CONNECTOR_PATH
npm install
node_modules/gulp/bin/gulp.js build
popd

echo "Building Gui"
[[ $RELEASE == true ]] && clear_gui
npm install
npm install common/node-connector
node_modules/bower/bin/bower --allow-root install
node_modules/gulp/bin/gulp.js prepare-files

[[ $RELEASE == true ]] && release || echo "non-release"
