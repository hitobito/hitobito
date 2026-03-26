# Papertrail
[Homepage]([Homepage](https://github.com/paper-trail-gem/paper_trail?tab=readme-ov-file))

With papertrail we can track the changes to our models for auditing or versioning. We can
find out how a model looked at any stage in its lifecycle, we can revert it to that lifecycle or restore
it after it has been destroyed.

## Example in Hitobito
In Hitobito we use the papertrail in different models. Let's take a look to the participation model:

```
class Event::Participation < ActiveRecord::Base

  has_paper_trail meta: {main_id: ->(p) { p.id },
                         main_type: sti_name},
    skip: [:id, :created_at, :event_id, :participant_id, :participant_type,
      :application_id, :active]
```

With the `has_paper_trail` expression we tell our application that it should track the changes of this model.
The meta expression is used to add additional columns to the Papertrail entity. In this example we have a `main_id`
column which takes the id of the person of the role and second a `main_type` which holds the `sti_name` of a person.

The skip expression tells us which field of the models should not be stored in the versions entity of papertrail. Per default those skip options include updated_at. As soon as a model like Event::Participation add own skip options locally, updated_at must be included too because the defaults get overriden.

### Paper Trail Versions for Translations
To maintain a clean version history, we prevent PaperTrail from creating versions on the base model when translated attributes change. Instead, we delegate versioning to the specific translation records. Let's take a look to the event model where translations are paper trailed:

```
  # To prevent issues of having paper trail versions when we don't want/need them, we add all
  # translated attributes to the skip list and create own paper trail versions on the
  # translation classes
  paper_trail_options[:skip] |= (translated_attribute_names.map(&:to_s) +
                                     globalize_attribute_names.map(&:to_s))

  translation_class.class_eval do
    has_paper_trail meta: {
      main_id: ->(t) { t.event_id },
      main_type: sti_name
    }

    # This is used to display in log what language record actually changed. Currently those
    # values are just the strings from settings.yml, so the log does not display translated
    # language names
    def to_s(format = :default)
      locale.to_s
    end
  end

  # Resync paper trail skip options after another translated attribute
  # may have been added to a wagon
  def translates(...)
    super

    return unless respond_to?(:paper_trail_options)

    paper_trail_options[:skip] |= (translated_attribute_names.map(&:to_s) +
                                  globalize_attribute_names.map(&:to_s))
  end
```

We exclude all translated attribute names (e.g., name) and globalized accessors (e.g., name_de, name_en) from the base model's PaperTrail configuration. By default, Globalize accessors trigger ActiveRecord change tracking on the base model. Without this configuration, updating a translation would create two version records: one (mostly empty) on the Event and one on the Event::Translation. This implementation ensures a single version for translation changes. If those paper trail configs are added to the core, overridding the translates method to resync these skip for translated wagon attributes is also needed.

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

