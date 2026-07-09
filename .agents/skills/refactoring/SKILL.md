---
name: refactoring
description: Use when restructuring internal code in hitobito without changing external functionality — for future extensibility, performance, or maintainability.
---

# Refactoring

## Overview

Improves internal structure without changing functionality. The goal is future extension, performance gains, or better maintenance.

**REQUIRED BACKGROUND:** Use the `development` skill for the base process (spec-first, `rubocop`, `brakeman`, copyright notice, commit message) — it applies here too.

## When to Use

Structural changes with no intended behavior change. For new or changed functionality, use the `development` skill instead. For resolving a defect, use the `fixing-a-bug` skill instead.

## Process

1. Clarify the goal of the refactor with the user.
2. Follow the `development` skill's process.
3. Check for obvious edge cases related to the goal that are missing from the specs. Beyond that, new specs are optional.
