# Addresses

[TOC]

## Overview

It is possible to provide an auto-complete and a validation for addresses.
The Addresses are read from the Address model.

Currently, address entries are swiss addresses imported from Swiss Post.

## Import

If you have configured an API token, the addresses are imported every 6 months.
You can import manually with a rake-task:

  bundle exec rake address:import

The API-Token can be provided as environment variable `ADDRESSES_TOKEN`.

## Configuration

Configuration is generally done through `config/settings.yml`.
The key `addresses` contains a hash that has the following keys:

- url (hardcoded URL to the post.ch service providing the swiss addresses)
- token (access-token which is read from `ENV['ADDRESSES_TOKEN']`)
- imported_countries (a list of countries to be imported, currently only 'CH')

## Completion

In the person#edit view, the address is auto-completed from all entries in the
addresses-table. If Sphinx is present, sphinx indexes that table and answers
queries. Otherwise, the table is queried by the database.

The search-strategy is determined the same way as for the
people/group/event-full-text search. (See `app/controllers/concerns/full_text_search_strategy.rb`)
