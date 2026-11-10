# Minimization

## Overview

`People::Minimizer` minimizes a person. This is a softer alternative to deleting a person: it
keeps some fields, the person's id, and their event participations, and clears the rest of the
data.

`Person#minimized_at` records when a person was minimized. A new role clears it automatically
(`Role#reset_person_minimized_at`, `Event::Participation#reset_person_minimized_at`). There is no
separate "reactivate" action.

The `Person.not_minimized` scope hides a minimized person from group member lists, "Without
Roles", global search, person-picker typeaheads, households, and mailing list recipients.
`PersonAbility`'s `general.not_minimized` condition blocks every action on a minimized person,
including `:show`, no matter the acting user's permissions. So a minimized person's profile is not
accessible.

One filter is an exception: the people index can filter by a past role (`kind` `deleted`,
`inactive`, or `inactive_but_existing`). This filter still shows minimized people, so admins can
find them by role history. `Person::Filter::Role#include_minimized?` controls this, and
`Person::Filter::List` passes the result to `PersonReadables` as `include_minimized:`.

Event participation lists are a second exception. They still list a minimized participant,
because that data has its own retention requirement, but they never link to the person's profile.
When all name fields are blank, `Person#to_s` shows a translated placeholder
("(inaktive Person)") instead.

Statistics, role-based counts, exports, and `Event::ParticipationFilter` ignore minimization on
purpose: minimized people still count there, only lists, search, and selection hide them.

## Customizing

The core decides two things: minimized people are hidden from person-facing lists, and their
profile is blocked. The core does not decide what data gets cleared.

Each wagon decides that for itself: override `minimize` in your own `People::Minimizer`
extension, the same way you reopen other core classes (see [Wagons](../common/wagons.md)).

When a wagon view links to a person, wrap the link in `link_to_if(can?(:show, person), ...)`.
`can?(:show, person)` is false for a minimized person, so this hides the link instead of pointing
at a blocked profile.
