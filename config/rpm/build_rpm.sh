#!/bin/bash -e

if [[ (-z $BUILD_NUMBER) || (-z $RPM_NAME) ]]; then
  echo "Usage: BUILD_NUMBER=123 RPM_NAME=hitobito build_rpm.sh"
  exit 1
fi

# set variables
VERSION=`grep -E '^%define app_version' hitobito/config/rpm/*.spec | head -n 1 | awk '{ print $3 }'`

# tag all repositories
for dir in hitobito*; do
	(cd $dir; git tag -a build_$BUILD_NUMBER -m "automatic build tag $BUILD_NUMBER")
done

# compose sources
DIR=$RPM_NAME-$VERSION.$BUILD_NUMBER
TAR=$DIR.tar.gz
mkdir -p sources/vendor/wagons

(cd hitobito; git archive --format=tar build_$BUILD_NUMBER) | (cd sources && tar -xf -)
for dir in hitobito_*; do
    mkdir -p sources/vendor/wagons/$dir
	(cd $dir; git archive --format=tar build_$BUILD_NUMBER) | (cd sources/vendor/wagons/$dir && tar -xf -)
done

# comment the next line out if your project includes submodules
#(git submodule --quiet foreach "pwd | awk -v dir=`pwd`/ '{sub(dir,\"\"); print}'") | xargs tar c | (cd sources && tar -xf -)

# config sources
sed -i s/BUILD_NUMBER/$BUILD_NUMBER/ sources/config/rpm/*.spec
sed -i s/RPM_NAME/$RPM_NAME/ sources/config/rpm/*.spec
mv -f sources/config/rpm/Wagonfile sources

# tar sources
mv sources $DIR
tar czf $TAR $DIR
rm -rf $DIR

# build source rpm
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

# notification trap function
function notifyFailure {
  if [ $? -gt 0 ]; then
    echo "Failed building RPM for $plat - See above for issues. Below we provide you with the logs from mock"
    #for logfile in /var/lib/mock/$plat/result/*log; do
    logfile=/var/lib/mock/$plat/result/build.log;
      echo "###############################################"
      echo "# ${logfile}"
      echo "###############################################"
      echo
      cat $logfile
      echo
    #done
    echo "Deleting also build-tag: build_${BUILD_NUMBER}"
    git tag -d build_$BUILD_NUMBER
  fi
}
trap notifyFailure EXIT

# build rpms
for plat in $BUILD_PLATFORMS; do
  eval "/usr/bin/mock -v --disable-plugin=package_state -D '__xz /usr/bin/pxz'  -r $plat --rebuild $build_flags $SRPM"
done

# uncomment this line if you want to push build tags to the git server
# ATTENTION: jenkins ldap user must have write rights to your git repository
#git push --tags
