#!/bin/bash

# Creates a universal deployable directory including wagons, assets and all
# required gems.
# Put the core and all desired wagons into one main folder, run this script
# from there and continue with the output in the sources folder.
# The shared folder contains artifacts that are reusable over multiple runs.
# Run this script with the same ruby version activated as on the target server.
# Database and transifex environment variables have to be set.

BUNDLE_WITHOUT='development:test:metrics:console'
EXCLUDE_DIRS='doc spec test vendor/cache log tmp .rspec Wagonfile.ci \
              .rubocop.yml .editorconfig .project rubocop-* .tx'

if [[ !( -z $BUILD_NUMBER ) ]]; then
  BUILD_TAG="build_$BUILD_NUMBER"
else
  BUILD_TAG="build"
fi

function bundleExec {
  echo $@
  RAILS_ENV=production RAILS_HOST_NAME='build.example.com' bundle exec $@
}

function copySource {
  (cd $1; git tag -a $BUILD_TAG -m "automatic build tag $BUILD_TAG")
  mkdir -p $2
  (cd $1; git archive --format=tar $BUILD_TAG) | (cd $2 && tar -xf -)
}


# prepare directories
rm -rf sources
mkdir -p shared/{bundle,assets}

# add core sources
copySource hitobito sources

# add wagon sources
for dir in hitobito_*; do
  if [[ ( -d $dir ) ]]; then
    copySource $dir sources/vendor/wagons/$dir
  fi
done

cd sources

# store build version
if [[ !( -z $BUILD_NUMBER ) ]]; then
  echo "`cat VERSION`.$BUILD_NUMBER" > VERSION
fi

# add load-all Wagonfile
mv -f config/rpm/Wagonfile .

# install gems
rsync -a ../shared/bundle vendor/
bundle install --path vendor/bundle --clean --without $BUNDLE_WITHOUT
rsync -a --delete vendor/bundle ../shared/

# fix gem shebangs
grep -sHE '^#!/usr/(local/)?bin/ruby' vendor/bundle -r | \
  awk -F: '{ print $1 }' | \
  uniq | \
  while read line; do
    sed -i 's@^#\!/usr/\(local/\)\?bin/ruby@#\!/bin/env ruby@' $line;
  done

# generate assets
rsync -a ../shared/assets public/
bundleExec rake assets:precompile assets:clean[0]
rsync -a --delete public/assets ../shared/

# generate error pages
RAILS_GROUPS=assets bundleExec rails generate error_pages

# download translation files
if [[ !( -z $RAILS_TRANSIFEX_HOST ) && ( -z $RAILS_TRANSIFEX_DISABLED ) ]]; then
  echo "[$RAILS_TRANSIFEX_HOST]
hostname = $RAILS_TRANSIFEX_HOST
password = $RAILS_TRANSIFEX_PASSWORD
token =
username = $RAILS_TRANSIFEX_USERNAME
" > ~/.transifexrc

  bundleExec rake tx:pull tx:wagon:pull -t
fi

# remove unnecessary files
for dir in $EXCLUDE_DIRS; do
  [ -e $dir ] && rm -rf $dir
done
rm -f ~/.transifexrc

# recreate empty directories
mkdir tmp log
chmod -R o-rwx .

cd ..

# uncomment this line if you want to push build tags to the git server
# ATTENTION: jenkins ldap user must have write rights to your git repository
#if [[ !( -z $BUILD_NUMBER ) ]]; then
#  git push --tags
#fi
