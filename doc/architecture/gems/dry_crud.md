# DRY CRUD

[Homepage](https://github.com/codez/dry_crud)

DRY-CRUD was used to generate several classes like the CrudController to generalize CRUD actions for our models.

## Example in Hitobito

The CRUD Controller defines all basic CRUD actions:

```
def create(options = {}, &block)
  assign_attributes
  created = with_callbacks(:create, :save) { save_entry }
  respond_with(entry, options.reverse_merge(success: created, location: return_path), &block)
end
```

We can then inherit from this CRUD-controller to access all of this CRUD actions without having to
implement them again:

`class RolesController < CrudController`

If we still want to add custom behaviour to our controller actions we can simply overwrite the actions and fill
them with our custom logic:

```
def create
  assign_attributes
  with_person_add_request do
  new_person = entry.person.new_record?
  created = create_entry_and_person
  add_privacy_policy_not_accepted_error if new_person
  return destroy_and_redirect if destroy_on_create?
    respond_with(entry, success: created, location: after_create_location(new_person))
  end
end
```

