#!/bin/bash

PACKAGE=virtdb-gui

if [ "X" == "X$GITHUB_USER" ]; then echo "Need GITHUB_USER environment variable"; exit 10; fi
if [ "X" == "X$GITHUB_PASSWORD" ]; then echo "Need GITHUB_PASSWORD environment variable"; exit 10; fi
if [ "X" == "X$GITHUB_EMAIL" ]; then echo "Need GITHUB_EMAIL environment variable"; exit 10; fi
if [ "X" == "X$HOME" ]; then echo "Need HOME environment variable"; exit 10; fi

cd build-result

rm -rf $PACKAGE/*
rm -rf $PACKAGE/.*

git clone --recursive https://$GITHUB_USER:$GITHUB_PASSWORD@github.com/starschema/$PACKAGE.git $PACKAGE
if [ $? -ne 0 ]; then echo "Failed to clone virtdb-gui repository"; exit 10; fi
echo Creating build $BUILDNO

echo >>$HOME/.netrc
echo machine github.com >>$HOME/.netrc
echo login $GITHUB_USER >>$HOME/.netrc
echo password $GITHUB_PASSWORD >>$HOME/.netrc
echo >>$HOME/.netrc

cd $HOME/build-result/$PACKAGE

PROTOC_PATH=$(which protoc)
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${PROTOC_PATH%/bin/protoc}/lib/pkgconfig

git --version
git config --global push.default simple
git config --global user.name $GITHUB_USER
git config --global user.email $GITHUB_EMAIL

# -- figure out the next release number --
function release {
  pushd $HOME/$PACKAGE
  echo "Creating release"

  # -- tagging release
  VERSION=`npm version patch`
  git add package.json
  if [ $? -ne 0 ]; then echo "Failed to add package.json to patch"; exit 10; fi
  git commit -m "Increased version number to $VERSION"
  # if [ $? -ne 0 ]; then echo "Failed to commit patch $VERSION"; exit 10; fi
  git push
  if [ $? -ne 0 ]; then echo "Failed to push to repo."; exit 10; fi

  RELEASE_PATH="$HOME/build-result/$PACKAGE-$VERSION"
  mkdir -p $RELEASE_PATH
  cp --parents common/proto/*.desc $RELEASE_PATH
  cp -R static $RELEASE_PATH
  cp -R server $RELEASE_PATH
  cp -R node_modules $RELEASE_PATH
  cp app.js $RELEASE_PATH
  pushd $RELEASE_PATH/..
  tar cvfj $PACKAGE-$VERSION.tbz $PACKAGE-$VERSION
  rm -Rf $PACKAGE-$VERSION
  popd

  git tag -f $VERSION
  if [ $? -ne 0 ]; then echo "Failed to tag repo"; exit 10; fi
  git push origin $VERSION
  if [ $? -ne 0 ]; then echo "Failed to push tag to repo."; exit 10; fi
  popd
}

[[ ${1,,} == "release" ]] && RELEASE=true || RELEASE=false

echo "building gui"
npm install
if [ $? -ne 0 ]; then echo "npm install failed for $PACKAGE"; exit 10; fi
node_modules/bower/bin/bower --config.analytics=false --config.interactive=false install
if [ $? -ne 0 ]; then echo "bower install failed"; exit 10; fi
node_modules/gulp/bin/gulp.js prepare-files
if [ $? -ne 0 ]; then echo "failed to prepare-files"; exit 10; fi

echo "start tests"
node_modules/mocha/bin/mocha --compilers=coffee:coffee-script/register test/*.coffee --reporter=tap > test-report.xml
node_modules/gulp/bin/gulp.js coverage
if [ $? -ne 0 ]; then echo "testing failed for $PACKAGE"; exit 10; fi

[[ $RELEASE == true ]] && release || echo "non-release"
