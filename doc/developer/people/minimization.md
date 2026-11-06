# Minimization

## Overview

Minimizing a person (`People::Minimizer`) is the archive-friendly alternative to deleting
them: it keeps selected fields, their id and historical event participations around while 
redacting the rest of their data. `Person#minimized_at` is set when this happens, 
and cleared automatically as soon as the person gets a new role again
(`Role#reset_person_minimized_at`, `Event::Participation#reset_person_minimized_at`) 
— there is no separate "reactivate" action.

A minimized person is hidden everywhere people are listed, searched or picked (group member
lists, "Without Roles", global search, person-picker typeaheads, households, mailing list
recipients) via the `Person.not_minimized` scope, and their profile becomes inaccessible via
`PersonAbility`'s `general.not_minimized` condition, which denies every action (including `:show`)
on a minimized person regardless of the acting user's permissions.

The one deliberate exception is the personal filter on the people index: filtering by a past role
(`kind` `deleted`, `inactive` or `inactive_but_existing`) still surfaces minimized people, so admins
can find them when browsing by role history. `Person::Filter::Role#includes_minimized?` drives this,
and `Person::Filter::List` passes it through as `include_minimized:` to `PersonReadables`.

Event participation lists are a second, narrower exception: they keep listing a minimized
participant (that data has its own retention requirement) but never link to their profile, and
`Person#to_s` falls back to a translated placeholder ("(inaktive Person)") when every name field is
blank.

Statistics, role-based counts, exports and `Event::ParticipationFilter` are deliberately left
alone — minimized people still count there, only lists/search/selection hide them.

## Customizing

The core only decides *that* minimized people are hidden from person-facing lists and *that* their
profile is blocked — it never decides what actually gets cleared. Each wagon decides that for
itself by overriding `minimize` in its own `People::Minimizer` extension (reopened the same way
other core classes are, see [Wagons](../common/wagons.md)).
