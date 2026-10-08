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
CSS and JS are compiled with esbuild/dart-sass via yarn scripts called from rake tasks, and served via Propshaft
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
When researching something across all existing wagons, always ignore the archived, unmaintained dav and kljb wagons.

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
2. `bin/rails db:test:prepare` there, once per directory, before the first spec run. It loads the
   core schema and builds the assets of that directory's test composition; the first spec run applies
   the wagon migrations. To rebuild only the assets, run `bin/rails assets:build_for_test` in the
   core or `bin/rails app:assets:build_for_test` in a wagon.
3. `bundle exec rspec spec/...` for the specs themselves.

# Code Comments and documenting code

Comments in code mostly age poorly. Please use the following framework to decide how to document changes:
1. First and foremost, **make the code speak for itself**. Methods, variables and specs MUST be
   split and named to be self-explanatory.
2. Add documentation to the dedicated places: `doc/` in the core and wagons, and the
   `hitobito/user_documentation` repository published at hitobito.readthedocs.io.
3. Prefer commit messages to code comments, because a git blame is more telling and easier to
   research than figuring out the cross-repo code state back when a comment was written. Match the
   style and length of other, human-made commits (without 🤖 emoji). No figures of speech, just
   objective facts in short form. NEVER more than 1 commit line + 3 lines of commit message.
4. A CHANGELOG.md entry is only made for user-facing changes (including JSON:API changes).
5. Only if the information is directly about the class / method being commented, only if it can't
   be expressed through the above means of documentation adequately, and only if it is relevant
   every single time a piece of code is read, forever: Only then create a comment. Even then,
   only include the information that isn't covered in the other docs locations, and don't mention
   the other docs locations either. If a decision is detailed in an issue, it will already be
   referenced in the commit message, so no need for rephrasing or linking.

**Guiding Principles** for writing documentation and especially the rare comments:
- NEVER reference comments, method names or implementation locations from other files. These will
  be outdated very quickly.
- NEVER narrate, retell or even mention earlier versions or decisions from previous iterations in
  the conversation history, or how it used to be implemented. Any documentation must be written
  as if this was the first ever implementation, and understandable by anyone without any history,
  context or memories.
- When there are other comments in the touched files already, any new comments MUST be shorter
  and rarer than the existing ones. MAXIMUM BREVITY.

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


Please follow the mandatory contribution rules in `../hitobito/CONTRIBUTING.md`, especially:
- CI must be green. If doing changes in the core, at least the core CI must be green before
  maintainers can look at your contribution.
- For all but the smallest bugfixes, the review of your contribution must be paid by your
  organization. So please check with them first, whether they are ready to carry this for your
  contribution.
- Larger feature changes should be discussed via an issue first, since the maintainers likely
  have domain knowledge about other wagons affected by your change. After all, merging your PR
  means the maintainers accept to carry the maintenance burden of your new feature in the long
  run.

Additionally, if your contribution has been created with AI, please add the emoji "🤖"
(:robot-face:) to commit messages and pull-request titles and descriptions. This helps us
categorize and fast-track the relevant contributions.
