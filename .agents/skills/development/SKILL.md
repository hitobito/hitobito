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
2. Write a spec first, defining the desired state. It must fail before any implementation exists.
3. Implement the change.
4. Do not touch locales other than `de`.
5. Confirm the spec now passes.
6. Run the specs for all touched classes to catch regressions.
7. Update the copyright notice at the top of touched files to cover the current year.
8. Run `brakeman` — no new security findings.
9. Run `rubocop` — code style must be clean.
10. Write a commit message summarizing the need for the change.
