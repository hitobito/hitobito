# Overview

This project is a web-application with the following stack:

- Ruby
- Ruby On Rails
- PostgreSQL
- Delayed::Job
- Redis

Hitobito is a web application to manage organizations and communities with complex group hierarchies
with people, events, courses and mail-sending features. A brief overview of the application is in
the README.md.

The HTML is mostly generated server-side with HAML.
The Testing Framework is rspec, with capybara.
Static analysis is done with rubocop and brakeman.
CSS and JS are processed with webpacker.
Translations are handled externally, the german (de) locales are the source and under our control.

# Repository Layout

hitobito is split across several git repositories, checked out next to each other in one directory:

- `hitobito` — the core. This file lives there.
- `hitobito_*` — the wagons: customer-specific extensions. Not necessarily the ones in use: the
  docker dev setup checks out only the wagons of its instance, while a native setup often has every
  existing hitobito wagon there.
- the directory containing them — in the docker dev setup a `hitobito/development` checkout that
  ties them together; in a native setup just a directory.

When investigating behaviour, read the core first and then every **active** wagon that is present:
wagons regularly reopen and monkeypatch core classes instead of subclassing them, or activate or
deactivate feature toggles.

# Core Domain Models

- People belong to a Group through the person's Roles.
- Groups are organized hierarchically and have different layers. A layer is a group whose
  `layer_group_id` points at itself; for every other group it points at the owning layer's group,
  which may be several levels up the tree.
- Roles define permissions which use CanCanCan and a custom AbilityDsl.
- Roles are considered active for a time range (`start_on`/`end_on`) and are generally
  soft-deleted by setting `end_on`.

## Additional concepts and folders

- `../hitobito/app/abilities` for RBAC with CanCanCan. The AbilityDsl declaratively expresses
  conditions like "people with roles with permission `layer_full` may update people in
  `group.layer_group_id`", and lists are scoped in SQL rather than filtered per record — read
  [Berechtigungen](doc/architecture/08_konzepte.md#berechtigungen) before touching permissions or a
  list query.
- `../hitobito/app/domain` for business logic and query objects that do not belong to a single model
  (cross-model search, reporting, lifecycle rules).
- Wagons are Rails engines that reopen core classes instead of subclassing them, so a core change
  can break them — read [Wagons](doc/developer/common/wagons.md).
- German is the only locale under our control, everything else comes from Transifex — read
  [Internationalization](doc/developer/common/i18n.md) before editing any locale file.
- Preventing N+1 queries is mandatory, not an optimization for later — read
  [Performance](doc/developer/common/performance.md) before writing a query, a list or an export.

# Architecture

hitobito consists of a core and one or more wagons (plugins), each a different git repository.
Wagons are mostly Rails' engines, just with a different loading order. See the
[wagon integration doc](../hitobito/doc/architecture/wagons/README.md) if information is needed.

The group structure of the final application is always defined in a wagon, along with all
modifications needed by that final application (also called the instance).

# Environment & Execution Rules

Determine your environment before running anything:

**1. `IS_DOCKER_DEV_ENV` is set — you are inside the docker dev setup's container.**
- Read `../AGENTS_DOCKER_SETUP.md` before running any command.
- The PostgreSQL host is `postgres`.
- Only the currently needed wagons are present, in `../hitobito_*`.

**2. `IS_DOCKER_DEV_ENV` is not set, but `../docker-compose.yml` exists — the docker dev setup is in
use and you are running on the host, outside the containers.**
- There is no Ruby, no PostgreSQL and no Redis available to you here. Do not try to install any.
- Stop and tell the user to restart you inside the container, from this directory:
  `../bin/agent claude` (or `../bin/agent opencode`).

**3. Neither — native setup, with Ruby, PostgreSQL and Redis installed on the host.**
- Run commands normally using `bin/rails` and `bundle exec rspec`.
- Ensure PostgreSQL is running locally.
- Potentially all existing wagons are checked out next to the core, and the needed ones are
  selected by the ENV var `WAGONS`. This is defined in the `Wagonfile`, which is included into the
  `Gemfile`.

# Running Specs

1. **`cd` to the directory whose specs you want first** — the core for core specs, the wagon
   directory for that wagon's specs.
2. `bin/rails db:test:prepare` there, once per directory, before the first spec run. It builds the
   whole schema — for a wagon that is the core schema plus that wagon's own migrations.
3. `bundle exec rspec spec/...` for the specs themselves.

# Dependencies

Both dev setups configure the locally checked out wagons in `Wagonfile`, which bundler would then
write into `Gemfile.lock` as `path:` entries pointing at `../hitobito_*`. To keep that out of the
committed lockfile, they run bundler against a `Gemfile.local` / `Gemfile.local.lock` copy.

So when you add, remove or update a gem, the change has to be made in `Gemfile` and picked back
over into the committed `Gemfile.lock` — the `Gemfile.local` pair is local scaffolding and is
gitignored. Read
[Avoid changes in Gemfile.lock due to local wagon configuration](../hitobito/doc/developer/local_setup.md#avoid-changes-in-gemfilelock-due-to-local-wagon-configuration)
before touching either file, and never commit a `Gemfile.lock` containing `../hitobito_*` paths.

# Contribution Guidelines

If your contribution has been created with AI, please add the emoji "🤖" (:robot-face:) to
commit messages and pull-request titles and descriptions. This helps us categorize and fast-track
the relevant contributions.
