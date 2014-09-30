#!/bin/sh
git checkout master
git submodule update --init --recursive
git submodule update --init --remote --recursive
git pull --recurse-submodules
git checkout master
git remote add upstream https://github.com/starschema/virtdb-gui.git
git fetch origin -v
git fetch upstream -v
git merge upstream/master
git status
