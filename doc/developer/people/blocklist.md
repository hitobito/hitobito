# Blocklist

## Overview

People on the blocklist cannot be created again. Enable it with
`Settings.people.blocklist.enabled`. People with `:admin` manage the entries in the settings.

Only an MD5 hash is stored, e.g. `MD5(".max.mustermann.1980-01-15 00:00:00")` for first name,
last name and birthday, stripped and downcased. Hashes from other systems in this format may be
imported directly into `blocklist_entries.blocked_hash`.

## Customizing

Wagons may change the hashed person attributes with `Person::BlocklistDetector.hash_attrs`.
Only plain person attributes are supported for now.
