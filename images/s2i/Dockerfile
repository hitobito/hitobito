# HOW TO DEPLOY CHANGES TO THIS:
#
# Changes to this file will eventually get deployed
# when OpenShift deploys the base image due to
# security patches to the FROM image given below.
#
# If you want to manually deploy them, change into
# the OpenShift-Project, start the build 'rails-sti',
# wait for both the builds 'rails-sti' and 'rails'
# to finish and start the CI job that you'd normally
# use to deploy.
#
# (Using the CLI, you can achieve this by running
# `oc start-build rails-sti-base`)

FROM centos/ruby-25-centos7

USER root

RUN \
    mv $STI_SCRIPTS_PATH/assemble $STI_SCRIPTS_PATH/assemble-base && \
    mv $STI_SCRIPTS_PATH/run $STI_SCRIPTS_PATH/run-base

ADD ./root /

RUN \
    yum localinstall -y \
      "https://github.com/sphinxsearch/sphinx/releases/download/2.2.11-release/sphinx-2.2.11-1.rhel7.x86_64.rpm" && \
    scl enable rh-ruby25 /opt/bin/install-nodejs && \
    yum install -y python-setuptools && \
    scl enable rh-ruby25 /opt/bin/install-transifex && \
    wget https://kojipkgs.fedoraproject.org//packages/sqlite/3.8.11/1.fc21/x86_64/sqlite-devel-3.8.11-1.fc21.x86_64.rpm &&  \
    wget https://kojipkgs.fedoraproject.org//packages/sqlite/3.8.11/1.fc21/x86_64/sqlite-3.8.11-1.fc21.x86_64.rpm && \
    yum install -y sqlite-3.8.11-1.fc21.x86_64.rpm sqlite-devel-3.8.11-1.fc21.x86_64.rpm && \
    chmod ugo+x $STI_SCRIPTS_PATH/* && \
    # TODO Why do we do this?
    # Check with the fix-permissions call in $STI_SCRIPTS_PATH/assemble.
    chgrp -R 0 ./ && \
    chmod -R g+rw ./ && \
    find ./ -type d -exec chmod g+x {} + && \
    chown -R 1001:0 ./ && \
    yum install ImageMagick ImageMagick-devel -y && \
    yum clean all -y

# BUNDLE_WITHOUT is a workaround for the base image:
# Do not install gems from development and test environments.
ENV \
    BUNDLE_WITHOUT=development:test \
    RAILS_ENV=production \
    RAILS_ROOT=/opt/app-root/src \
    RUBY_GC_HEAP_INIT_SLOTS=1800000 \
    RUBY_HEAP_FREE_MIN=18000 \
    RUBY_HEAP_SLOTS_INCREMENT=144000 \
    RUBY_HEAP_SLOTS_GROWTH_FACTOR=1 \
    RUBY_GC_MALLOC_LIMIT=60000000

USER 1001
