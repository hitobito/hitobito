#!/bin/sh

if [ -z $BUILD_NUMBER ]; then
  echo "Usage: BUILD_NUMBER=123 build_rpm.sh"
  exit 1
fi
git tag -a build_$BUILD_NUMBER -m "automatic build tag $BUILD_NUMBER"
NAME=`grep -E '^%define app_name' config/rpm/*.spec | head -n 1 | awk '{ print $3 }'`
VERSION=`grep -E '^%define app_version' config/rpm/*.spec | head -n 1 | awk '{ print $3 }'`
DIR=$NAME-$VERSION.$BUILD_NUMBER
TAR=$DIR.tar.gz
mkdir $DIR
git archive --format=tar build_$BUILD_NUMBER | (cd $DIR && tar -xf -)
sed -i s/BUILD_NUMBER/$BUILD_NUMBER/ $DIR/config/rpm/*.spec
tar czf $TAR $DIR
rm -rf $DIR
build=`rpmbuild -ts $TAR`
if [ $? -gt 0 ]; then
  echo "Failed building SRPM"
  echo $build
  exit 1
fi
rm $TAR
SRPM=`echo $build | grep Wrote | tail -n 1 | awk -F': ' '{ print $2 }'`
build_flags=$(env | grep RAILS_ | while read line; do echo -n " --define=\"$(echo $line | sed "s/=/ /")\""; done)

if [ -z $BUILD_PLATFORMS ]; then
  BUILD_PLATFORMS='epel-6-x86_64'
fi
for plat in $BUILD_PLATFORMS; do
  eval "mock -r $plat --rebuild $build_flags $SRPM"
  if [ $? -gt 0 ]; then
    echo "Failed building RPM for $plat - See above for issues."
    exit 1
  fi
done
#git push --tags
