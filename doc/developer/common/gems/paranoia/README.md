# Paranoia

[Homepage](https://github.com/rubysherpas/paranoia)

The `paranoia` gem overrides the destroy method of ActiveRecord. It overrides it to not actually destroy an object when
`destroy` called on it. Instead it _hides_ the object. Paranoia does this by setting a `deleted_at` field to the current time
when `destroy `is called on the model.

If you want to actually destroy the object you have to call `really_destroy!`. This will destroy the entity and all other
entities which **depend** on this object.

## Example in Hitobito

To activate paranoia we need to include the `acts_as_paranoid` expression in a model. Once this expression is inserted
the `destroy` method is overwritten.

```
class Role < ActiveRecord::Base

  has_paper_trail meta: { main_id: ->(r) { r.person_id },
  main_type: Person.sti_name },
  skip: [:updated_at]
  
  acts_as_paranoid
```

To check that this really worked you can call `destroy` on your entity check that the
`deleted_at` field has been set to the current timestamp.

```
>> role.deleted_at
# => nil
>> role.destroy
# => client
>> role.deleted_at
# => [current timestamp]
```
