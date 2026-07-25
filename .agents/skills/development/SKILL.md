---
name: development
description: Use when implementing new or changed functionality in hitobito, before writing any implementation code.
---

# Development

## Overview

Workflow for new and changed functionality: start from a user-facing goal, drive the change through a failing spec, then implement.

## When to Use

Default workflow for feature work or behavior changes. For resolving a defect, use the `fixing-a-bug` skill instead. For structural changes with no behavior change, use the `refactoring` skill instead.

## Process

1. State the reason for the change — the goal describing how the application should improve for the user.
1. Work on a feature-branch, name it "feature/SHORT-NAME-OF-ISSUE"
1. Write a spec first, defining the desired state. It must fail before any implementation exists.
1. Implement the change.
1. Do not touch locales other than `de`, not even german variants like `de_CH` or `de_DE`.
1. Confirm the spec now passes.
1. Run the specs for all touched classes to catch regressions.
1. Update the copyright notice at the top of touched files to also cover the current year. The previous start should be preserved, e.g. 2015-2026
1. Run `bundle exec rake brakeman` — no new security findings.
1. Run `bundle exec rake rubocop` — code style must be clean. `bundle exec rake rubocop:changed` checks only the
   files you touched.
1. Write a commit message summarizing the need for the change.

## Rules

- DB-Migrations MUST be created with `bundle exec rails generate migration` to ensure proper filenames
