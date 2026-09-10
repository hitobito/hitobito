# Performance: avoiding N+1 Queries

hitobito runs on productive datasets with more than 100'000 people. An implementation that is not
performant at that size is not done — freedom from N+1 queries is part of the
[Definition of Done](../process/definition_of_done.md), not an optimization to do later.

## Rules

* Never query inside a loop, and never per rendered row. Anything a view, decorator, serializer,
  exporter or ability iterates over must be loaded up front with `includes` / `preload` /
  `eager_load` on the scope that builds the collection.
* Never resolve authorization for a list record by record. Use the readables/writables scopes
  described under
  [Berechtigungen auf Listen](../../architecture/08_konzepte.md#berechtigungen-auf-listen) so the
  database does the filtering.
* Reuse the existing preloading helpers instead of inventing new ones: `Person::PreloadGroups`
  (`Person.preload_groups`), `Person::PreloadPublicAccounts`, `PreloadRolesUnscoped`,
  `Event::PreloadAllDates`, `Event::Participation::PreloadParticipations`,
  `Invoice::PreloadRecipients`. Aggregations belong in the scope too, e.g.
  `Invoice.with_aggregated_payments`.
* Load only what you need: `Person.only_public_data` for lists, `pluck`/`select` over instantiating
  records, `find_each` for large batches.
* A custom `TableDisplays::Column` that needs extra tables must join them in its query hook rather
  than loading them per row — see `app/domain/table_displays/column.rb`.

## Verifying

In development, [bullet](../../../config/initializers/bullet.rb) is enabled and reports N+1 queries
and unused eager loading to the log and into the page footer — check it after touching a list view.
Genuine exceptions are safelisted in its initializer, with a comment explaining why; add to that
list only when the query really cannot be avoided.

For code paths where the query count matters, pin it in a spec with the query helpers from
`spec/support/query_helpers.rb`:

```ruby
expect { get :index, params: {group_id: group.id} }.to make(57).db_queries
```

A spec like this fails loudly when a change reintroduces an N+1, which a functional spec would not.
