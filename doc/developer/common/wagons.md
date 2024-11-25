# Wagons

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
