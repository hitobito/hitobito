FROM ruby:2.3.7-alpine
MAINTAINER Diego P. Steiner diego.steiner@u041.ch
RUN apk add --no-cache --update build-base \
  linux-headers \
  git \
  nodejs \
  mariadb-dev \
  sqlite-dev \
  tzdata
# RUN apt-get update -qq && apt-get install -y build-essential \
# libxml2-dev libxslt1-dev libqt4-webkit libqt4-dev xvfb nodejs

RUN mkdir -p /app
WORKDIR /app

#COPY Gemfile /app/
#COPY Gemfile.lock /app/
#RUN gem install bundler && bundle install --jobs 20 --retry 5
#COPY . /app
