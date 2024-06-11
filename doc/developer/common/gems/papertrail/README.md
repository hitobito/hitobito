# Papertrail
[Homepage]([Homepage](https://github.com/paper-trail-gem/paper_trail?tab=readme-ov-file))

With papertrail we can track the changes to our models for auditing or versioning. We can
find out how a model looked at any stage in its lifecycle, we can revert it to that lifecycle or restore
it after it has been destroyed.

## Example in Hitobito
In Hitobito we use the papertrail in different models. Let's take a look to the role model:

```
class Role < ActiveRecord::Base

  has_paper_trail meta: { main_id: ->(r) { r.person_id },
  main_type: Person.sti_name },
  skip: [:updated_at]
```

With the `has_paper_trail` expression we tell our application that it should track the changes of this model.
The meta expression is used to add additional columns to the Papertrail entity. In this example we have a `main_id`
column which takes the id of the person of the role and second a `main_type` which holds the `sti_name` of a person.

The skip expression tells us which field of the models should not be stored in the versions entity of papertrail, in our
case that's the `updated_at` field.

## Access versions
You can access the different versions of a model by entering the rails console with `rails c`
Then you get the first role and save it inside a variable with `role = Role.first`. After executing this
command you can access the versions created by papertrail of this entity by using `role.versions`.

The output should look something like this.

```
[#<PaperTrail::Version:0x00007fac5b146e78
id: 79,
item_type: "Role",
item_id: 1,
event: "create",
whodunnit: nil,
object: nil,
object_changes:
"---\nid:\n-\n- 1\nperson_id:\n-\n- 2\ngroup_id:\n-\n- 1\ntype:\n-\n- Group::TopLayer::Administrator\ncreated_at:\n-\n- 2024-05-24 06:28:15.000000000 Z\n",
main_type: "Person",
main_id: 2,
created_at: Fri, 24 May 2024 08:28:15.000000000 CEST +02:00,
whodunnit_type: "Person">]
```

