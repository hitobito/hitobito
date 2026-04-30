# check=skip=SecretsUsedInArgOrEnv

#################################
#          Variables            #
#################################

# Versioning
ARG RUBY_VERSION="4.0"
ARG BUNDLER_VERSION="4.0.6"
ARG NODEJS_VERSION="16"
ARG YARN_VERSION="1.22.19"
ARG DEBIAN_VERSION="trixie"

# Packages
# BUILD_PACKAGES are used in the targets build and dev
ARG BUILD_PACKAGES="nodejs git build-essential libpq-dev libvips42"
# DEV_PACKAGES are used in the target dev
ARG DEV_PACKAGES="direnv xvfb chromium chromium-driver pv vim curl less sudo"
# RUN_PACKAGES are used in the target app
ARG RUN_PACKAGES="shared-mime-info pkg-config libpq-dev libjemalloc-dev libjemalloc2 libvips42 libicu76"
# EXTRA_PACKAGES are used in the targets build, app and dev
ARG EXTRA_PACKAGES=""

# Scripts
ARG PRE_INSTALL_SCRIPT="\
  apt-get update && \
  apt-get install -y ca-certificates curl gnupg && \
  mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODEJS_VERSION}.x nodistro main' > /etc/apt/sources.list.d/nodesource.list && \
  echo 'Package: nodejs' >> /etc/apt/preferences.d/preferences && \
  echo 'Pin: origin deb.nodesource.com' >> /etc/apt/preferences.d/preferences && \
  echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/preferences \
"
ARG INSTALL_SCRIPT="node -v && npm -v && npm install -g yarn && yarn set version ${YARN_VERSION}"
ARG PRE_BUILD_SCRIPT="\
     git submodule status | tee WAGON_VERSIONS; \
     rm -rf hitobito/.git; \
     mv hitobito/* hitobito/.?* .; \
     mkdir -p vendor/wagons; \
     for wagon_dir in hitobito_*; do if [[ -d \$wagon_dir ]]; then rm -rf \$wagon_dir/.git && mv \$wagon_dir vendor/wagons/; fi; done; \
     rm -rf hitobito; \
     cp -v Wagonfile.production Wagonfile; \
     bundle lock; \
"
ARG BUILD_SCRIPT="RAILS_DB_ADAPTER=nulldb bundle exec rake assets:precompile"

ARG POST_BUILD_SCRIPT=" \
     echo \"(built at: $(date '+%Y-%m-%d %H:%M:%S'))\" > /app-src/BUILD_INFO; \
     bundle exec bootsnap precompile app/ lib/; \
"

# Bundler specific
ARG BUNDLE_WITHOUT_GROUPS="development:metrics:test"

# App specific
ARG RAILS_ENV="production"
ARG RACK_ENV="production"
ARG NODE_ENV="production"
ARG RAILS_HOST_NAME="unused.example.net"
ARG SECRET_KEY_BASE="needs-to-be-set"

# Runtime ENV vars
ARG SENTRY_CURRENT_ENV
ARG HOME=/app-src
ARG PS1="[\$SENTRY_CURRENT_ENV] `uname -n`:\$PWD\$ "
ARG TZ="Europe/Zurich"


#################################
#   Prepping the dependencies   #
#################################

FROM ruby:${RUBY_VERSION}-${DEBIAN_VERSION} AS runtime

# arguments for steps
ARG HOME
ARG PRE_INSTALL_SCRIPT
ARG BUILD_PACKAGES
ARG EXTRA_PACKAGES
ARG INSTALL_SCRIPT
ARG BUNDLER_VERSION

# arguments potentially used by steps
ARG NODE_ENV
ARG RACK_ENV
ARG RAILS_ENV
ARG RAILS_HOST_NAME
ARG SECRET_KEY_BASE
ARG TZ

# Set build shell
SHELL ["/bin/bash", "-c"]

# Use root user
USER root

RUN bash -vxc "${PRE_INSTALL_SCRIPT:-"echo 'no PRE_INSTALL_SCRIPT provided'"}"

# Install dependencies
RUN    export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ${BUILD_PACKAGES} ${EXTRA_PACKAGES}

RUN bash -vxc "${INSTALL_SCRIPT:-"echo 'no INSTALL_SCRIPT provided'"}"

# Explicitly install specific versions of bundler
# (not required with newer bundler versions?)
RUN gem install bundler:${BUNDLER_VERSION} --no-document


#################################
#  Build for Development Stage  #
#################################

FROM runtime AS dev

ARG DEV_PACKAGES
ARG USERNAME=hitobito
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV RAILS_ENV="development"
ENV RACK_ENV="development"
ENV NODE_ENV="development"

ENV HOME=/home/developer
ENV RAILS_DB_ADAPTER=postgresql
ENV BUNDLE_PATH=/opt/bundle
ENV NODE_PATH=/usr/lib/nodejs

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get install -y --no-install-recommends ${DEV_PACKAGES}

WORKDIR /usr/src/app/hitobito

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash -d $HOME \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME

# Prepare Docker cli install to be able to use it in the devcontainer
RUN export DEBIAN_FRONTEND=noninteractive \
 && mkdir -p /etc/apt/keyrings \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list

# Preinstall github.com ssh host keys
# You can find the keys at https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
RUN mkdir -p $HOME/.ssh \
    && echo "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl" >> $HOME/.ssh/known_hosts \
    && echo "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" >> $HOME/.ssh/known_hosts \
    && echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=" >> $HOME/.ssh/known_hosts \
    && chmod 600 $HOME/.ssh/known_hosts \
    && /usr/bin/ssh-keygen -H -f $HOME/.ssh/known_hosts \
    && chown -R $USERNAME:$USERNAME $HOME/.ssh

# This depends on the dev-setup.
COPY ./rails-entrypoint.sh /usr/local/bin
COPY ./webpack-entrypoint.sh /usr/local/bin

RUN mkdir -p /opt/bundle && chmod 777 /opt/bundle
RUN mkdir /seed && chmod 777 /seed

USER $USERNAME

ENTRYPOINT ["rails-entrypoint.sh"]
CMD [ "rails", "server", "-b", "0.0.0.0" ]

#################################
#   Build for Deployment Stage  #
#################################

FROM runtime AS build

# arguments for steps
ARG PRE_BUILD_SCRIPT
ARG BUNDLE_WITHOUT_GROUPS
ARG BUILD_SCRIPT
ARG POST_BUILD_SCRIPT

# arguments potentially used by steps
ARG NODE_ENV
ARG RACK_ENV
ARG RAILS_ENV
ARG RAILS_HOST_NAME
ARG SECRET_KEY_BASE
ARG TZ

# set up app-src directory
WORKDIR $HOME

# copy entire submodule structure because it is needed for the PRE_BUILD_SCRIPT
COPY . .

# only copy things needed for bundling
# COPY Gemfile Gemfile.lock Wagonfile.production ./

RUN bash -vxc "${PRE_BUILD_SCRIPT:-"echo 'no PRE_BUILD_SCRIPT provided'"}"

# install gems and build the app
RUN    bundle config set --local deployment 'true' \
    && bundle config set --local without ${BUNDLE_WITHOUT_GROUPS} \
    && bundle install \
    && bundle clean \
    && bundle exec bootsnap precompile --gemfile \
    && bundle exec rails locales:patch_de

# only copy things needed for yarning
# COPY package.json yarn.lock ./
# COPY .yarn ./.yarn/
# install npms for the frontend
RUN yarn install --immutable

# copy entire application code after dependencies are built
# COPY . .

RUN bash -vxc "${BUILD_SCRIPT:-"echo 'no BUILD_SCRIPT provided'"}"

RUN bash -vxc "${POST_BUILD_SCRIPT:-"echo 'no POST_BUILD_SCRIPT provided'"}"

RUN rm -rf vendor/cache/ .git spec/ node_modules/ .npm/

#################################
#         Run/App Stage         #
#################################

FROM ruby:${RUBY_VERSION}-slim-${DEBIAN_VERSION} AS app

# Set runtime shell
SHELL ["/bin/bash", "-c"]

# arguments for steps
ARG RUN_PACKAGES
ARG EXTRA_PACKAGES
ARG BUNDLER_VERSION
ARG BUNDLE_WITHOUT_GROUPS

# data persisted in the image
ARG PS1
ARG TZ
ARG HOME
ARG NODE_ENV
ARG RACK_ENV
ARG RAILS_ENV

# Set environment variables available in the image
ENV PS1="${PS1}" \
    TZ="${TZ}" \
    HOME="${HOME}" \
    PATH="${HOME}/bin:$PATH" \
    NODE_ENV="${NODE_ENV}" \
    RAILS_ENV="${RAILS_ENV}" \
    RACK_ENV="${RACK_ENV}"

# Install dependencies, remove apt!
RUN    export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y ${RUN_PACKAGES} ${EXTRA_PACKAGES} adduser vim curl less \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && truncate -s 0 /var/log/*log

# Add user
RUN adduser --disabled-password --uid 1001 --gid 0 --comment "" app

# only after it has been installed
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# Copy deployment ready source code from build
COPY --from=build $HOME $HOME
WORKDIR $HOME

# Create pids folder for puma and
# set group permissions to folders that need write permissions.
RUN mkdir -p tmp/pids log \
    && chgrp 0 $HOME \
    && chgrp -R 0 $HOME/tmp \
    && chgrp -R 0 $HOME/log \
    && chmod u+w,g=u $HOME \
    && chmod -R u+w,g=u $HOME/tmp \
    && chmod -R u+w,g=u $HOME/log \
    && chmod a+w $HOME/db/schema.rb \
    && chmod a+w $HOME/vendor/wagons/*/db/seeds/

# Install specific versions of dependencies
RUN gem install bundler:${BUNDLER_VERSION} --no-document

# Use cached gems
RUN    bundle config set --local deployment 'true' \
    && bundle config set --local without ${BUNDLE_WITHOUT_GROUPS} \
    && bundle install

# These args contain build information. Also see build stage.
# They change with each build, so only define them here for optimal layer caching.
# Also see https://docs.docker.com/engine/reference/builder/#impact-on-build-caching
ARG BUILD_REPO
ARG BUILD_REF
# ARG BUILD_DATE
ARG BUILD_COMMIT
ARG HITOBITO_PROJECT
ARG HITOBITO_STAGE

ENV BUILD_REPO="${BUILD_REPO}" \
    BUILD_REF="${BUILD_REF}" \
    # BUILD_DATE="${BUILD_DATE}" \
    BUILD_COMMIT="${BUILD_COMMIT}" \
    HITOBITO_PROJECT="${HITOBITO_PROJECT}" \
    HITOBITO_STAGE="${HITOBITO_STAGE}"

# Set runtime user (although OpenShift uses a custom user per project instead)
USER 1001

CMD ["bundle", "exec", "puma"]
