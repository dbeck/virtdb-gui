#!/bin/bash

if [ "X" == "X$GITHUB_USER" ]; then echo "Need GITHUB_USER environment variable"; exit 10; fi
if [ "X" == "X$GITHUB_PASSWORD" ]; then echo "Need GITHUB_PASSWORD environment variable"; exit 10; fi
if [ "X" == "X$GITHUB_EMAIL" ]; then echo "Need GITHUB_EMAIL environment variable"; exit 10; fi
if [ "X" == "X$HOME" ]; then echo "Need HOME environment variable"; exit 10; fi

cd $HOME

git clone --recursive https://$GITHUB_USER:$GITHUB_PASSWORD@github.com/starschema/virtdb-gui.git virtdb-gui
if [ $? -ne 0 ]; then echo "Failed to clone virtdb-gui repository"; exit 10; fi
echo Creating build 

echo >>$HOME/.netrc
echo machine github.com >>$HOME/.netrc
echo login $GITHUB_USER >>$HOME/.netrc
echo password $GITHUB_PASSWORD >>$HOME/.netrc
echo >>$HOME/.netrc

cd $HOME/virtdb-gui

git --version
git config --global push.default simple
git config --global user.name $GITHUB_USER
git config --global user.email $GITHUB_EMAIL

# -- figure out the next release number --
function release {
  pushd $HOME/virtdb-gui
  echo "Creating release"

  # -- tagging release
  VERSION=`npm version patch`
  git add package.json
  if [ $? -ne 0 ]; then echo "Failed to add package.json to patch"; exit 10; fi
  git commit -m "Increased version number to $VERSION"
  # if [ $? -ne 0 ]; then echo "Failed to commit patch $VERSION"; exit 10; fi
  git push
  if [ $? -ne 0 ]; then echo "Failed to push to repo."; exit 10; fi

  RELEASE_PATH="$HOME/build-result/virtdb-gui-$VERSION"
  mkdir -p $RELEASE_PATH
  cp --parents common/proto/*.desc $RELEASE_PATH
  cp -R static $RELEASE_PATH
  cp -R server $RELEASE_PATH
  cp -R node_modules $RELEASE_PATH
  cp app.js $RELEASE_PATH
  pushd $RELEASE_PATH/..
  tar cvfj virtdb-gui-$VERSION.tbz virtdb-gui-$VERSION  
  rm -Rf virtdb-gui-$VERSION
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
if [ $? -ne 0 ]; then echo "npm install failed for virtdb-gui"; exit 10; fi
node_modules/bower/bin/bower --config.analytics=false --config.interactive=false install
if [ $? -ne 0 ]; then echo "bower install failed"; exit 10; fi
node_modules/gulp/bin/gulp.js prepare-files
if [ $? -ne 0 ]; then echo "failed to prepare-files"; exit 10; fi

echo "start tests"
export JUNIT_REPORT_PATH=test_report.xml
export JUNIT_REPORT_STACK=1
./node_modules/.bin/mocha --compilers=coffee:coffee-script/register --reporter mocha-jenkins-reporter test/*.coffee
if [ $? -ne 0 ]; then echo "testing failed for virtdb-gui"; exit 10; fi

[[ $RELEASE == true ]] && release || echo "non-release"
