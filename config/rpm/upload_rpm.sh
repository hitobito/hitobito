#!/bin/bash -e

if [[ (-z $BUILD_NUMBER) || (-z $RPM_NAME) || (-z $PULP_REPO) ]]; then
  echo "Usage: BUILD_NUMBER=123 RPM_NAME=hitobito PULP_REPO=autobuild upload_rpm.sh"
  exit 1
fi

rpmdir="/var/lib/mock/epel-6-x86_64/result"

if [ ! -f $rpmdir/$RPM_NAME-*.rpm ]; do
  echo "no rpm file for given project for upload found."
  echo "rpm name: ${RPM_NAME}"
  echo "rpm location: ${rpmdir}"
  exit 1
fi

for rpm in $rpmdir/$RPM_NAME-*.rpm; do
  /usr/local/bin/upload_rpm_to_pulp.sh $PULP_REPO $rpm || exit 1
done
