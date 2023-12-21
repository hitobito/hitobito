#################################
#          Variables            #
#################################

# Keep ruby version in sync with the Hitobito Dockerfile
# Some tests depend on the ruby version.

# Versioning
ARG RUBY_VERSION="3.2"
ARG BUNDLER_VERSION="2.5.6"
ARG NODEJS_VERSION="16"
ARG YARN_VERSION="1.22.19"
ARG TRANSIFEX_VERSION="1.6.4"

# Packages
ARG BUILD_PACKAGES="nodejs git sqlite3 libsqlite3-dev imagemagick build-essential default-libmysqlclient-dev"
ARG DEV_PACKAGES="direnv xvfb chromium chromium-driver default-mysql-client pv vim curl less"

#################################
#          Build Stage          #
#################################

FROM ruby:${RUBY_VERSION} AS build

USER root

ENV RAILS_ENV=development
ENV RAILS_DB_ADAPTER=postgresql
ENV BUNDLE_PATH=/opt/bundle

WORKDIR /usr/src/app/hitobito

ARG NODEJS_VERSION
RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && apt-get install -y ca-certificates curl gnupg \
 && mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODEJS_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
 && echo "Package: nodejs" >> /etc/apt/preferences.d/preferences \
 && echo "Pin: origin deb.nodesource.com" >> /etc/apt/preferences.d/preferences \
 && echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/preferences

ARG BUILD_PACKAGES
ARG DEV_PACKAGES
RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends ${BUILD_PACKAGES} \
 && apt-get install -y --no-install-recommends ${DEV_PACKAGES}

ARG YARN_VERSION
RUN node -v && npm -v && npm install -g yarn && yarn set version "${YARN_VERSION}"

ARG TRANSIFEX_VERSION
RUN curl -L "https://github.com/transifex/cli/releases/download/v${TRANSIFEX_VERSION}/tx-linux-amd64.tar.gz" | tar xz -C /usr/local/bin/

ARG BUNDLER_VERSION
RUN bash -vxc "gem install bundler -v ${BUNDLER_VERSION}"

# for release and version-scripts
RUN bash -vxc 'gem install cmdparse pastel'

COPY ./rails-entrypoint.sh /usr/local/bin
COPY ./webpack-entrypoint.sh /usr/local/bin
COPY ./waitfortcp /usr/local/bin

RUN mkdir /opt/bundle && chmod 777 /opt/bundle
RUN mkdir /seed && chmod 777 /seed
RUN mkdir /home/developer && chmod 777 /home/developer
ENV HOME=/home/developer
ENV NODE_PATH=/usr/lib/nodejs

ENTRYPOINT ["rails-entrypoint.sh"]
CMD [ "rails", "server", "-b", "0.0.0.0" ]
