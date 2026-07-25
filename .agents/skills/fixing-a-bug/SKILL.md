---
name: fixing-a-bug
description: Use when fixing a bug, unhandled exception, or edge-case error of unknown or unclear cause in hitobito, before writing implementation code.
---

# Fixing a Bug

## Overview

Workflow for resolving an error that affects a user — typically an edge case or data-based exception that isn't currently handled.

## When to Use

Any bugfix task: reproducing and resolving a defect. For new functionality, use the `development` skill instead. For structural changes with no behavior change, use the `refactoring` skill instead.

## Process

1. State the reason for the bugfix — the error affecting the user.
1. Verify `bundle exec rake rubocop` and `bundle exec rake brakeman` report no errors locally before starting.
1. Write a spec that reproduces the bug BEFORE changing any other code. It must fail first.
1. Implement the fix.
1. Do not touch locales other than `de`, not even german variants like `de_CH` or `de_DE`.
1. Confirm the spec now passes.
1. Update the copyright notice at the top of touched files to also cover the current year. The previous start should be preserved, e.g. 2015-2026
1. Run `bundle exec rake brakeman` — no new security findings.
1. Run `bundle exec rake rubocop` — code style must be clean. `bundle exec rake rubocop:changed` checks only the
   files you touched.
1. Write a commit message summarizing the need for the change.

## Rules

- DB-Migrations MUST be created with `bundle exec rails generate migration` to ensure proper filenames
