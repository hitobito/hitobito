FROM centos/ruby-26-centos7

USER root

ENV RAILS_ENV=development
ENV BUNDLE_PATH=/opt/bundle
WORKDIR /opt/app-root/src/hitobito

ENTRYPOINT /opt/app-root/src/hitobito/.docker-dev/rails-entrypoint
