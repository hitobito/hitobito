# Waiting List for Events

## Overview

Once an event has no open spots left, further applications can be put on a
waiting list.

## Activating the Feature

This needs to activated in the individual wagon, the attribute `:waiting_list`
needs to be added to the list of `used_attributes` of the Events.

Waiting lists are only available on Event-Types that support applications. This
is a class-level attribute (`supports_applications`). By default, this is only
the case for `Event::Course`.

## Using the Waiting List

When the feature is activated in the wagon, enabled events have the option to
activate the waiting list for the individual event in the tab "Application"
("Anmeldung"). The checkbox "Waiting List" ("Warteliste") sends applications
that are over the limit to a waiting list. The waiting list reuses the
Application Marketplace interface.

If applications need or want to cancel, organizing staff can assign people from
the waiting list to the event.
