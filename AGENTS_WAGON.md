# You are working in a hitobito wagon

This repository is a **wagon**: a Rails engine that customizes hitobito for one organization. It
does not run, boot or test standalone — it always needs the hitobito core, which is checked out
next to it as `../hitobito`.

**Read `../hitobito/AGENTS.md` now, before planning, editing or running anything.** Everything in
it applies here: the repository layout, the environment detection (docker dev setup vs. native
setup), the domain model and the spec protocol. This file only adds what is specific to working
inside a wagon.

## What belongs here

The wagon holds customization such as the group structure of the final application (the *instance*).
The generic framework — people, groups, roles, events, abilities, mailing — lives in the core.
Wagons regularly reopen and monkeypatch core classes instead of subclassing them, and activate or
deactivate feature toggles in config/settings.yml, so before changing anything, get a full picture
of the feature in the core and all **active** wagons.

## Working in this directory

- Run specs, static analysis and rake tasks from this directory, not from the core.
- Follow the core's spec protocol: `bin/rails db:test:prepare` once per checkout or worktree, then
  `bundle exec rspec`. This directory gets its own isolated test database.
- Skills are available through the `.claude` and `.opencode` symlinks; they point into the core, so
  the same workflows apply here.
