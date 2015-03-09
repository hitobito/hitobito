#!/bin/bash

# Creates a deployable tarball for openshift.
#
# Put the core and all desired wagons into one main folder, run this script
# from there and you get the file deployment.tar.gz as output.
# See bin/package.sh for additional information.


hitobito/bin/package.sh

rm -rf deployment
mkdir -p deployment/{dependencies,build_dependencies}

mv sources deployment/repo
mv deployment/repo/vendor/bundle/ruby/*/* deployment/repo/vendor/bundle/ruby
mkdir -p deployment/repo/deployments

cd deployment
tar cf - . | pigz -9 > ../deployment.tar.gz
