#!/bin/bash -e

if [[ (-z $BUILD_NUMBER) || (-z $RPM_NAME) || (-z $PULP_REPO) ]]; then
  echo "Usage: BUILD_NUMBER=123 RPM_NAME=hitobito PULP_REPO=autobuild upload_rpm.sh"
  exit 1
fi

rpmdir="/var/lib/mock/epel-6-x86_64/result"

for rpm in $rpmdir/$RPM_NAME-*.rpm; do
  echo "uploading ${rpm} to pulp repo ${PULP_REPO}"
  /usr/local/bin/upload_rpm_to_pulp.sh $PULP_REPO $rpm || exit 1
done
