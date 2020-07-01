FROM centos/ruby-26-centos7

USER root

ENV RAILS_ENV=development
ENV BUNDLE_PATH=/opt/bundle
WORKDIR /opt/app-root/src/hitobito
RUN yum remove -y ${RUBY_SCL}-rubygem-bundler
RUN bash -c 'gem install bundler -v 2.1.4'

ENTRYPOINT /opt/app-root/src/hitobito/.docker-dev/rails-entrypoint
