#!/bin/bash

# This script is intended to be used as a kubernetes liveness check.
# The rake delayed job worker sometimes dies, e.g. because he cannot connect to the database.
# We make sure both the worker and searchd are running, if not this container should be restarted.

running_processes=$(ps -aux | grep -E 'jobs:work|/usr/bin/searchd' | grep -v grep | wc -l)
expected_processes=2

if (( $running_processes < $expected_processes )); then
    echo "Unhealthy."
    exit 1
fi
