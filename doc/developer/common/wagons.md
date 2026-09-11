# Wagons

Wagons are the organisation-specific extensions of the generic core. Each one is its own git
repository next to the core, and the group structure of a concrete instance is always defined in a
wagon. How to create one, define a group structure and add attributes is described in the
[wagon architecture doc](../../architecture/wagons/README.md).

## Engine structure and load order

A wagon is a Rails engine. Its entry point is `lib/hitobito_[name]/wagon.rb`:

```ruby
module HitobitoYouth
  class Wagon < Rails::Engine
    include Wagons::Wagon

    app_requirement ">= 0"

    config.autoload_paths += %W[#{config.root}/app/abilities #{config.root}/app/domain]

    config.to_prepare do
      Person.include Youth::Person
      EventAbility.include Youth::EventAbility
      PeopleController.permitted_attrs += [:nationality_j_s, :j_s_number]
    end
  end
end
```

Consequences to keep in mind:

* **Wagons reopen core classes, they do not subclass them.** The customization lives in a
  namespaced concern (`app/models/youth/person.rb` → `Youth::Person`) that is included into the
  core class in `config.to_prepare`. Grep for the core class name in every active wagon before
  concluding what a method does.
* Loading order is core first, then wagons — so a wagon always wins, and two wagons can conflict.
* Wagons share the core's database. Their migrations live in the wagon's `db/migrate` and are
  *not* part of the core `schema.rb`; a wagon's test schema is the core schema plus that wagon's
  migrations.
* Group and role types, seeds (`db/seed`) and fixtures (`spec/fixtures`) of an instance are
  defined in its wagon, not in the core.
* Extending a model from a wagon usually means all of: a migration, adding the attribute to
  `Person::PUBLIC_ATTRS` if it must be readable in the optimized list queries, `permitted_attrs`
  in a controller concern, the views, the exports and the JSON API — see
  [Adding attributes](../../architecture/wagons/README.md#instructions-adding-attributes).
* Abilities are extended the same way and constraints may be overridden, see
  [Berechtigungen](../../architecture/08_konzepte.md#berechtigungen).
* A wagon's `Gemfile.lock` is never checked into git.

**Core changes must keep the wagons working.** When you change a core class that wagons are likely
to reopen (`Person`, `Group`, `Role`, `Event`, the abilities, the controllers), check the active
wagons for a concern that patches the method or relies on its signature.

## View Helpers

### `render_extensions`

tbd

### `render_core_partial`

let's say you want to customize a certain partial in a wagon, but then inside this partial want to fallback to the core's definition.

$wagon/app/views/roles/_fields.html.haml
```haml
- if my_wagon_check
  = render 'something/wagon/specific'
- else
  = render_core_partial 'roles/fields'
```
