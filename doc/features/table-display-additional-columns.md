# Table display / additional columns

[TOC]

## Overview

In some lists, such as person and event participation lists, it is possible for
the users to display some additional columns, such as birthday, company name or
login status.

The available columns have to be explicitly registered in the code, for security
reasons.
In the core, this is done in the initializer table_displays.rb, in the wagons
it can be done in wagon.rb.

## DSL

### Simple columns

An example of registering three columns at once:
```
TableDisplay.register_column(Person,
                             TableDisplays::ShowFullColumn,
                             [:ahv_number, :j_s_number, :nationality_j_s])
```

This registers new columns on the `Person` list.
The third line contains a list of attributes which should be newly selectable.

The second line specifies the column class which should be used for these new
selectable columns.
The column class is responsible for...
- providing a label for the column
- permission checking. In this case, `:show_full` on the person is required in
order to display the AHV number of the person. The permission is evaluated
separately for each person in the displayed list.
- formatting the value displayed in the table
- augmenting the database query with any additional selects or joins which are
needed for calculating the displayed value

For simple public columns which require no permission check, there is an even
more basic column class `PublicColumn`.

### Calculated columns

For more complicated or calculated columns, there are also specific column
classes, such as `LoginStatusColumn`.
This type of column would typically only be registered with a single attribute:
```
TableDisplay.register_column(Person,
                             TableDisplays::People::LoginStatusColumn,
                             :login_status)
```

### Multi-columns

It is also possible to create a column class which dynamically creates multiple
columns at runtime.
This is needed e.g. for event questions, where each event can have a different
set of questions, and the event participation list should offer to select only
the relevant questions from its event.

To register such a dynamic multi-column, the DSL looks like this:
```
TableDisplay.register_multi_column(Event::Participation,
                                   TableDisplays::Event::Participations::QuestionColumn)
```

Multi-columns can only be registered one at a time, because each multi-column
can produce multiple actual columns.
