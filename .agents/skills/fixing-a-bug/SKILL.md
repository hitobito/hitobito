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
2. Verify `rubocop` and `brakeman` report no errors locally before starting.
3. Write a spec that reproduces the bug BEFORE changing any other code. It must fail first.
4. Implement the fix.
5. Do not touch locales other than `de`.
6. Confirm the spec now passes.
7. Update the copyright notice at the top of touched files to cover the current year.
8. Run `brakeman` — no new security findings.
9. Run `rubocop` — code style must be clean.
10. Write a commit message summarizing the need for the change.
