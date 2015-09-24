# Deployment with Openshift

## Preparation

Prepare your machine for deployment with Openshift:

  gem install rhc

  rhc setup

## Setup

Create an application with ruby and mysql on your Openshift server:

  rhc -ahitobito app create -gmedium ruby-2.0 mysql-5.5 --no-git

This creates an application named 'hitobito' in a medium sized gear.

These additional cartridges are required:

* cron
  rhc -ahitobito cartridge add cron

* memcached
  rhc -ahitobito cartridge add http://cartreflect-claytondev.rhcloud.com/github/puzzle/openshift-memcached-cartridge

* sphinx
  rhc -ahitobito cartridge add http://cartreflect-claytondev.rhcloud.com/github/puzzle/openshift-sphinx-cartridge

## Deployment

Package the application with

  .openshift/bin/binary-package.sh

Then Deploy the package:

  rhc -ahitobito app deploy deployment.tar.gz

## Intraction

Login with SSH to your application server:

  rhc -ahitobito ssh

Tail all application logs:

  rhc -ahitobito tail

On the server, opening a Rails console:

  cd app-root/repo
  ruby_context "rails c"

## More

General information for deploying Ruby on Rails application in Openshift:

https://developers.openshift.com/en/ruby-getting-started.html

For information about .openshift directory, consult the documentation:

http://openshift.github.io/documentation/oo_user_guide.html#the-openshift-directory
