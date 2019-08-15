FROM centos/ruby-22-centos7

USER root

RUN \
    mv $STI_SCRIPTS_PATH/assemble $STI_SCRIPTS_PATH/assemble-base && \
    mv $STI_SCRIPTS_PATH/run $STI_SCRIPTS_PATH/run-base

ADD ./root /

RUN \
    yum localinstall -y \
      "https://github.com/sphinxsearch/sphinx/releases/download/2.2.11-release/sphinx-2.2.11-1.rhel7.x86_64.rpm" && \
    scl enable rh-ruby22 /opt/bin/install-nodejs && \
    scl enable rh-ruby22 /opt/bin/install-transifex && \
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
