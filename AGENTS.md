# Overview

This project is a web-application with the following stack:

- Ruby
- Ruby On Rails
- PostgreSQL
- Delayed::Job
- Redis

Hitobito is a web application to manage organisation and communities with complex group hierarchies with people, events, courses and mail-sending features
A brief overview of the application is in the README.md.

The HTML is mostly generated server-side with HAML.
The Testing Framework is rspec, with capybara.
Static analysis is done with rubocop and brakeman.
CSS and JS are processed with webpacker
Translations are handled externally, the german (de) locales are the source and under our control.

# Core Models

- People belong to a Group through the persons Roles.
- Groups are organized hierarchically and have different layers.
- Roles define permissions which use CanCanCan and a custom AbilityDsl.

## additional concepts and folders

- app/abilities for RBAC with CanCanCan

# Architecture

hitobito consists of a core and one or more wagons. Wagons are mostly Rails' engines, just with a different loading order. See the [wagon integration doc](./doc/architecture/wagons/README.md) if information is needed. In the dev-setup, the needed wagons are located next to the core, so the core (this repo) is at `../hitobito/` while the wagons are in `../hitobito_*`. In some setups, only the currently needed ones are there, in others, all wagons are there, and the needed ones are selected by the ENV-Var `WAGONS`. In ruby, this is defined in the `Wagonfile`, which is included into the `Gemfile`.

When asked to research anything, also consider the currently used wagons.

The wagon always contains the group-structure of the final application and all modifications needed by that final application. The final application is also called the instance or the client-application (because our customer/client wants and needs that application).

# Contribution Guidelines

If your contribution has been created with AI, please add the emoji "🤖" (:robot-face:) to commit-messages and pull-request titles and descriptions. This helps us categorize and fast-track the relevant contributions.
