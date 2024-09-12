# Basic Permission on role

## Overview

Roles can be marked as `self.basic_permissions_only = true` via `class_attribute`.

This causes people with **only** such roles to have a very limited view and permissions.

## View

The left main navigation, search bar, parent group (sheet) and all person tabs excluding "Info" and "Sicherheit" are hidden.

## Permissions

Only `:show, :update, :update_email, :primary_group, :totp_reset` are allowed on themselves.
