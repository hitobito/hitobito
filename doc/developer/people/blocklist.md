# Blocklist

## Overview

People on the blocklist cannot be created again, and no new roles can be created for them. Enable
it with `Settings.people.blocklist.enabled`. People with `:admin` manage the entries in the
settings.

Only an MD5 hash is stored, e.g. `MD5(".max.mustermann.1980-01-15 00:00:00")` for first name,
last name and birthday, stripped and downcased. Dots in strings are replaced by `_`. Along with
each hash we also store the list of `hashed_attrs` which were included in the hash, and compare
this when checking for existing blocklist entries.

Mandatory attributes are always hashed, even if blank. Optional attributes are only hashed if
present. Blocking a person stores one entry for every combination of their present optional
attributes, so they are still detected when an optional attribute is omitted. Each entry records
its `hashed_attrs`, and only matches people with exactly these attributes present, so the same
value in another optional attribute does not match.

A person or role that cannot be created shows the id of the matching entry as reference number,
so admins can delete entries which block too broadly.

## Customizing

Wagons may change the mandatory hashed person attributes with
`Person::BlocklistDetector.hash_attrs` and the optional ones with
`Person::BlocklistDetector.optional_hash_attrs`.

Values are joined with dots, so a dot within a value could shift it into the next attribute. Wagons
adding attributes which are not strings must extend `Person::BlocklistDetector#normalize(attr, value)`
to replace dots in their values.
Only plain person attributes are supported for now, no phone numbers, additional emails, additional
addresses or social media.
