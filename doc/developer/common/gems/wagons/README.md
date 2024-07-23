# Wagons 🚃

Hitobito is divided into Core (generic part) and Wagon(s) (association-specific extensions). Wagons can be used to 
define a group structure, to adapt the behaviour of the application to user-specific requirements or to make certain features available to several organisations at the same time. At least one wagon with a group structure is required for Hitobito to run. Each wagon is managed in its own Git repo.

## Overview
* [Basics](#basics)
* [Every day development](#every-day-development---using-binwagon)
* [Create a wagon](#instructions-create-wagon)
* [Define group scope](#instructions-define-group-structure)
* [Customise individual method](#instructions-customise-individual-method)
* [Customise individual method](#instructions-customise-individual-method)
* [Adding attributes](#instructions-adding-attributes)
* [Modify functionality in wagon](wagon_changes.md)

## Basics

In development and production mode, both parts are loaded, in the tests
only the core or in the wagon tests the core and the specific wagon. This is controlled via the Gemfile
gemfile. For general information on how wagons work, see also
[wagons](http://github.com/codez/wagons).


Some basic things to note in connection with wagons:

* The hitobito core and all wagon directories must be in the same root directory.
* For development, the file `Wagonfile.ci` can be copied to `Wagonfile` to load all wagons in neighbouring directories.
  neighbouring directories. If only certain wagons are to be activated, this can also be
  can also be configured in `Wagonfile`.
* Wagons use the same database as the core. If migrations are created in the core,
  all wagon migrations must be removed from it before the `schema.rb` can be generated.
  The easiest way to do this is to completely delete and restore the development database.
  and restoring it.
* If new gems are added to the core, all `Gemfile.lock` files in the wagons must be updated.
  must be updated. The easiest way to do this is with `rake wagon:bundle:update`, or manually with
  `cp Gemfile.lock ../hitobito_[wagon]/`. The same applies if gems no longer fit when changing a wagon version.
  no longer fit. The `Gemfile.lock` of a wagon is NEVER checked into Git.
* A new wagon can be created with `rails g wagon [name]`. It should then be checked in from
  `vendor/wagons` into a neighbouring directory of the core and the file
  `app_root.rb` of the wagon should be adapted accordingly.

## Every day development - using ./bin/wagon

To facilitate working with various wagon (and therefore db schemas) it is
recommended to use the script `./bin/wagon`.

This script builds ontop of [direnv](https://direnv.net/). It controls various
environment variables to that wagons can be activated with a single statement.

## Instructions: create wagon

As a "Work in Progress" the wagon-creation is automated with

    ./bin/wagon create [name]

This covers the first few steps (up until and including the gemspec-changes) of the following instructions:

The basic structure of a new wagon can be easily generated in the main project, the templates for it are in `lib/templates/wagon`):

    rails generate wagon [name]

Afterwards you need to make the following adjustments:

* Move files from `hitobito/vendor/wagons/[name]` to `hitobito_[name]`
* Rename `github` to `.github` to enable GH-Actions
* Initialize a new Git Repo for the wagon
* Copy `.tool-versions` from the core into the wagon. (or use `wagon activate [name]`)
* Copy `Gemfile.lock` from the core into the wagon. (or use `wagon gemfile`)
* Optional: Copy local config from the core into the wagon. (or use `wagon configs`)
* Adjust Organisation in the license generator (`lib/tasks/license.rake`)  and add the licence everywhere with `rake app:license:insert`.
* Add the customer organization in `COPYING`.
* Put you name into `AUTHORS`
* Edit authors, email, summary und description `hitobito_[name].gemspec`.

If the wagon is the main wagon for a new organization structure, you can additionally do these steps:

* Add Developer and Client Accounts in the seed files: `db/seed/development/1_people.rb` under `devs`.
* Configure e-mail-adress for the root account in `config/settings.yml`.
* If the application is multilingual:
  * create a project in [Transifex](https://www.transifex.com/) (e.g. hitobito_pbs)
  * make sure there is all required locale files in the wagon's config/locales folder (all non default language files can be empty on init)
  * create .tx/config and add all files (you might copy it from [here](https://github.com/hitobito/hitobito_die_mitte/blob/master/.tx/config) or use rake tx:init)

* Also see the guidelines for internationalization

If the wagon is not for a specific organisation and does not define a group structure, you should delete the following files:

* group models: `rm -rf app/models/group/root.rb app/models/[name]/group.rb`
* Translations of those models in `config/locales/models.[name].de.yml`
* seed-data: `rm -rf db/seeds`

In order to have useful Testdata, adjust the fixtures in the wagon according to the generated organizational structure:

* Fixtures for people, groups, roles, events, ... (`spec/fixtures`)
* Groups can be created manually and then exported with `rake fixtures:groups` to have a realistic and usable set.

## Instructions: Define group structure

Once a new wagon has been created for an organisation, it is often necessary to define a group structure.
group structure must also be defined. How the corresponding models are structured is described in the
architecture documentation. Here are the individual steps that need to be taken to set up the
development environment:

* The very top group is at the beginning. Rename the class in `app/models/group/root.rb` accordingly (e.g.
  (e.g. ‘umbrella organisation’) and define the first roles.
* Adapt `app/models/[name]/group.rb#root_types` accordingly.
* Add translations for group and roles in `config/locales/models.[name].de.yml`.
* In `db/seed/development/1_people.rb` adjust the admin role for the developers.
* Customise the seed of the root group in `db/seed/groups.rb`.
* Adjust the type of the root group in `spec/fixtures/groups.yml`.
* Customise the role types in `spec/fixtures/roles.yml`.
* Execute tests
* Define further groups and roles including translations.
* Define seed data for the defined group types in `db/seed/development/0_groups.rb`.
* Define fixtures for the defined group types in `spec/fixtures/groups.yml`. It is recommended
  It is recommended to use the same groups as in the development seeds.
* Complete `README.md` with output from `rails hitobito:roles`.

## Instructions: Customise individual method

In the PBS Wagon, the `full_name` method was customised on the `Person` model.

The implementation in the core looks like this: (`hitobito/app/models/person.rb`)

     def full_name(format = :default)
       case format
       when :list then ‘#{last_name} #{first_name}’.strip
       else ‘#{first_name} #{last_name}’.strip
       end
     end

In the PBS Wagon there is a corresponding module with the user-specific code for the Person Model class: (`hitobito_pbs/app/models/pbs/person.rb`)

     module Pbs::Person
       ...
       extend ActiveSupport::Concern

       included do
         ...
         alias_method_chain :full_name, :title
         ...
       end
       ...

     def full_name_with_title(format = :default)
       case format
       when :list then full_name_without_title(format)
       else ‘#{title} #{full_name_without_title(format)}".strip
       end
     end

With `alias_method_chain` the method `#full_name_with_title` is called when `#full_name` is called. This method is also defined in this module. The implementation from the core is available under `#full_name_without_title`.

To ensure that the code in this module is adopted accordingly for the person model, this is included accordingly in `wagon.rb`: (`hitobito_pbs/lib/hitobito_pbs/wagon.rb`)

     Modul HitobitoPbs
       Klasse Wagon < Rails::Engine
         include Wagons::Wagon
         ...
         Person.send :include, Pbs::Person
         ...

## Instructions: Adding attributes

The following documentation describes how new attributes can be added to a model in an own wagon. For reasons of simplification, this documentation follows an example where the generic wagon is going to be adapted and the `Person` model gets two new attributes called `title` and `salutation`.

All mentioned files are created/adjusted in a dedicated wagon, not in the core application.

### Add new attributes to the database

In order to adapt the database structure and add the desired new attributes to the model, a new migration must be created by the following command, which is executed in the root directory of the wagon:

    $ bin/rails generate migration AddPeopleAttrs

This command will create a new migration file in the path `db/migrate/YYYYMMDDHHMMSS_add_people_attrs.rb` which in the end should look as follows:

    class AddPeopleAttrs < ActiveRecord::Migration
      def change
        add_column :people, :title, :string
        add_column :people, :salutation, :string
      end
    end

In this example, the data types of the attributes are set to strings.

### Mark attributes as public

Several queries to the database are optimized to only fetch the publically visible attributes. Therefore the model needs to know if the new attributes are public. The list of public attributes is an class-level array that you can extend from your Wagon like this:

```
module Pbs::Person
  extend ActiveSupport::Concern
  included do
    ...
    Person::PUBLIC_ATTRS << :title << :salutation
    ...
  end
end
```

If attributes are not in this list but need to be, you might see an `ActiveModel::MissingAttributeError`-Exception in the rails-server log.

### Permit attributes for editing

The new attributes must be included in the application logic. To do so, a new controller has to be created in `app/controllers/<wagon_namespace>/people_controller.rb` which permits the two attributes to be updated:

    module <wagon_namespace>
      module PeopleController
        extend ActiveSupport::Concern
        included do
          self.permitted_attrs += [:title, :salutation]
        end
      end
    end

### Show and edit attributes in the view

There are two views which have to be adapted regarding the `Person` model: On one side the show view of the person and on the other side the edit view of the person.

Create a new file in `app/views/people/_details_<wagon_namespace>.html.haml` with the following content:

    = render_attrs(entry, :title, :salutation)

Create a new file in `app/views/people/_fields_<wagon_namespace>.html.haml` with the following content:

    = f.labeled_input_fields :title, :salutation

It is important that these files start with `_details` respectively `_fields`. The core-application automatically includes/renders all files starting with `_details` and `_fields`. The subsequent characters (`_<wagon_namespace>`) can be chosen arbitrarily.

### Translate the attribute names

In order to display the attribute names properly in each language, the language files of all used languages must be adapted by simply adding the following lines to the `config/locales/models.<wagon_namespace>.<language_code>.yml`-files:

    attributes:
      person:
      title: <translation_for_title_attribute_in_corresponding_language>
      salutation: <translation_for_salutation_attribute_in_corresponding_language>

### Include attributes in the CSV/Excel Exports

If wished, the attributes can be included in the CSV-File that is generated when performing a contact export. For this inclusion, a new file in `app/domain/<wagon_namespace>/export/tabular/people/people_address.rb` with the following content must be created:

    module <wagon_namespace>
      module Export
        module Tabular
          module People
            module PeopleAddress
              extend ActiveSupport::Concern

              included do
                alias_method_chain :person_attributes, :title
              end

              def person_attributes_with_title
                person_attributes_without_title + [:title, :salutation]
              end
            end
          end
        end
      end
    end

### Make attributes searchable

The new attributes must be indexed in `app/indices/person_index.rb` where all indexes for Sphinx (the search tool that is used by hitobito) are defined.

    ThinkingSphinx::Index.define_partial :person do
      indexes title
    end

### Output attributes in the API

In order to provide the additional attributes in the API (the JSON-file of the object), the serializer for the people must be extended in `app/serializers/<wagon_namespace>/person_serializer.rb`:

    module <wagon_namespace>::PersonSerializer
      extend ActiveSupport::Concern
      included do
        extension(:details) do |_|
          map_properties :title, :salutation
        end
      end
    end

### Wire up above extensions

The newly created or updated `PeopleController`, the CSV export file and the serializer file for the API must also be defined in the wagon configuration file which is located in `lib/<wagon_name>/wagon.rb`.

    config.to_prepare do
        ...
        PeopleController.send :include, <wagon_namespace>::PeopleController
        Export::Tabular::People::PeopleAddress.send :include, <wagon_namespace>::Export::Tabular::People::PeopleAddress
        PersonSerializer.send :include, <wagon_namespace>::PersonSerializer
    end

### Write tests for attributes

Arbitrary tests cases can be defined in the `spec/` directory of the wagon. As an example, the following file (`spec/domain/export/tabular/people/people_address_spec.rb`) proposes a test case that checks whether the attributes are exported properly into the CSV-file:

    require 'spec_helper'
    require 'csv'

    describe Export::Tabular::People::PeopleAddress do

      let(:person) { people(:admin) }
      let(:simple_headers) do
        %w(Vorname Nachname Übername Firmenname Firma Haupt-E-Mail Adresse PLZ Ort Land
           Geschlecht Geburtstag Rollen Titel Anrede)
      end
      let(:list) { Person.where(id: person) }
      let(:data) { Export::Tabular::People::PeopleAddress.csv(list) }
      let(:csv)  { CSV.parse(data, headers: true, col_sep: Settings.csv.separator) }

      subject { csv }

      before do
        person.update!(title: 'Dr.', salutation: 'Herr', town: 'Bern')
      end

      context 'export' do
        its(:headers) { should == simple_headers }

        context 'first row' do
          subject { csv[0] }

          its(['Vorname']) { should eq person.first_name }
          its(['Nachname']) { should eq person.last_name }
          its(['Haupt-E-Mail']) { should eq person.email }
          its(['Ort']) { should eq person.town }
          its(['Geschlecht']) { should eq person.gender_label }
          its(['Rollen']) { should eq 'Administrator Verband' }
          its(['Titel']) { should eq 'Dr.' }
          its(['Anrede']) { should eq 'Herr' }
        end
      end

      context 'export_full' do
        its(:headers) { should include('Titel') }
        its(:headers) { should include('Anrede') }

        let(:data) { Export::Tabular::People::PeopleFull.csv(list) }

        context 'first row' do
          subject { csv[0] }

          its(['Titel']) { should eq 'Dr.' }
          its(['Anrede']) { should eq 'Herr' }
        end
      end
    end
