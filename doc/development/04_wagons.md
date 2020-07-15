## Wagons

Hitobito ist aufgeteilt in Core (generischer Teil) und Wagon(s) (Verbandsspezifische Erweiterungen). Um eine Gruppenstruktur zu definieren, das Verhalten der Applikation auf benutzerspezifische Bedürfnisse anzupassen oder gewisse Features für mehrere Organisationen gemeinsam verfügbar zu machen, können Wagons verwendet werden. Damit Hitobito lauffähig ist, wird mindestens ein Wagon mit einer Gruppenstruktur benötigt. Jeder Wagon wird in einem eigenen Git Repo verwaltet.

### Grundlegendes

Im Development und Production Mode sind jeweils beide Teile geladen, in den Tests
nur der Core bzw. in den Wagon Tests der Core und der spezifische Wagon. Dies wird über das Gemfile
gesteuert. Zur Funktionsweise von Wagons allgemein siehe auch
[wagons](http://github.com/codez/wagons).


Einige grundlegende Dinge, welche in Zusammenhang mit Wagons zu beachten sind:

* Der hitobito Core und alle Wagon Verzeichnisse müssen im gleichen Haupverzeichnis sein.
* Zu Entwicklung kann die Datei `Wagonfile.ci` nach `Wagonfile` kopiert werden, um alle Wagons in
benachbarten Verzeichnissen zu laden. Falls nur bestimmte Wagons aktiviert werden sollen, kann dies
ebenfalls im `Wagonfile` konfiguriert werden.
* Wagons verwenden die gleiche Datenbank wie der Core. Wenn im Core Migrationen erstellt werden,
müssen alle Wagon Migrationen daraus entfernt werden, bevor das `schema.rb` generiert werden kann.
Dies geht am einfachsten, indem die development Datenbank komplett gelöscht und wiederhergestellt
wird.
* Wenn neue Gems zum Core hinzugefügt werden, müssen alle `Gemfile.lock` Dateien in den Wagons
aktualisert werden. Dies geschieht am einfachsten mit `rake wagon:bundle:update`, oder manuell mit
`cp Gemfile.lock ../hitobito_[wagon]/`. Dasselbe gilt, wenn Gems beim Umstellen einer Wagon Version
nicht mehr passen. Das `Gemfile.lock` eines Wagons wird NIE ins Git eingecheckt.
* Ein neuer Wagon kann mit `rails g wagon [name]` erstellt werden. Danach sollte dieser von
`vendor/wagons` in ein benachbartes Verzeichnis des Cores verschoben werden und die Datei
`app_root.rb` des Wagons entsprechend angepasst werden.

### Every day development - using ./bin/wagon

To facilitate working with various wagon (and therefore db schemas) it is
recommended to use the script `./bin/wagon`. 

This script builds ontop of [direnv](https://direnv.net/). It controls various
environment variables to that wagons can be activated with a single statement. 

### Instructions: create wagon


The basic structure of a new wagon can be easily generated in the main project, the templates for it are in `lib/templates/wagon`):

    rails generate wagon [name]

Afterwards you need to make the following adjustments:

* Move files from `hitobito/vendor/wagons/[name]` to `hitobito_[name]`
* Initiate a new Git Repo for the wagon
* Copy `Gemfile.lock` from the core into the wagon.
* Copy `.tool-versions` from the core into the wagon.
* Adjust Organisation in the license generator (`lib/tasks/license.rake`)  and add the licence everywhere with `rake app:license:insert`.
* Add the customer organization in `COPYING`.
* Put you name into `AUTHORS`
* Edit authors, email, summary und description `hitobito_[name].gemspec`.

If the wagon is the main wagon for a new organization strutture, you can additionaly  do these steps:

* Add Developer and Client Accounts in the seed files: `db/seed/development/1_people.rb` under `devs`.
* Configure e-mail-adress for the root account in `config/settings.yml`.
* If the application is multilingual, we reccommend to create a project in [https://www.transifex.com/](Transifex)
* Also see the guidelines for internationalization

If the wagon is not for a specific organisation and does not define a group structure, you should delete the following files:

* group models: `rm -rf app/models/group/root.rb app/models/[name]/group.rb`
* Translations of those models in `config/locales/models.[name].de.yml`
* seed-data: `rm -rf db/seeds`

In order to have useful Testdata and to use tarantula, adjust the fixtures in the wagon according to the generated organizational structure:

* Fixtures for people, groups, roles, events, ... (`spec/fixtures`)
* Adjusting the tarantula tests in the wagon (`test/tarantula/tarantula_test.rb`)

### Anleitung: Gruppenstruktur definieren

Nachdem für eine Organisation ein neuer Wagon erstellt worden ist, muss oft auch eine 
Gruppenstruktur definiert werden. Wie die entsprechenden Modelle aufgebaut sind, ist in der 
Architekturdokumentation beschrieben. Hier die einzelnen Schritte, welche für das Aufsetzen der
Entwicklungsumgebung noch vorgenommen werden müssen:

* Am Anfang steht die alleroberste Gruppe. Die Klasse in `app/models/group/root.rb` entsprechend 
  umbenennen (z.B. nach "Dachverband") und erste Rollen definieren. 
* `app/models/[name]/group.rb#root_types` entsprechend anpassen.
* In `config/locales/models.[name].de.yml` Übersetzungen für Gruppe und Rollen hinzufügen.
* In `db/seed/development/1_people.rb` die Admin Rolle für die Entwickler anpassen.
* In `db/seed/groups.rb` den Seed der Root Gruppe anpassen.
* In `spec/fixtures/groups.yml` den Typ der Root Gruppe anpassen.
* In `spec/fixtures/roles.yml` die Rollentypen anpassen.
* Tests ausführen
* Weitere Gruppen und Rollen inklusive Übersetzungen definieren.
* In `db/seed/development/0_groups.rb` Seed Daten für die definierten Gruppentypen definieren.
* In `spec/fixtures/groups.yml` Fixtures für die definierten Gruppentypen definieren. Es empfielt
  sich, die selben Gruppen wie in den Development Seeds zu verwenden.
* `README.md` mit Output von `rake app:hitobito:roles` ergänzen.


### Anleitung: Einzelne Methode anpassen

Im PBS Wagon wurde die Methode `full_name` auf dem `Person` Model angepasst.

Die Implementation im Core sieht dabei folgendermassen aus: (`hitobito/app/models/person.rb`)

     def full_name(format = :default)
       case format
       when :list then "#{last_name} #{first_name}".strip
       else "#{first_name} #{last_name}".strip
       end
     end

Im PBS Wagon gibt es ein entsprechendes Modul mit dem benutzerspezifischen Code für die Person Model Klasse: (`hitobito_pbs/app/models/pbs/person.rb`)
 
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
       else "#{title} #{full_name_without_title(format)}".strip
       end
     end

Mit `alias_method_chain` wird beim Aufruf von `#full_name` die Methode `#full_name_with_title` aufgerufen. Diese Methode wird ebenfalls in diesem Modul definiert. Die Implementation aus dem Core steht unter `#full_name_without_title` zur Verfügung.

Damit der Code in diesem Module entsprechend für das Person Model übernommen wird, wird dies in der `wagon.rb` entsprechend included: (`hitobito_pbs/lib/hitobito_pbs/wagon.rb`)

     module HitobitoPbs
       class Wagon < Rails::Engine
         include Wagons::Wagon
         ...
         Person.send       :include, Pbs::Person
         ...


### Anleitung: Attribute hinzufügen 

The following documentation describes how new attributes can be added to a model in an own wagon. For reasons of simplification, this documentation follows an example where the generic wagon is going to be adapted and the `Person` model gets two new attributes called `title` and `salutation`.

All mentioned files are created/adjusted in a dedicated wagon, not in the core application.

#### Add new attributes to the database

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

#### Mark attributes as public

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
         
#### Permit attributes for editing

The new attributes must be included in the application logic. To do so, a new controller has to be created in `app/controllers/<wagon_namespace>/people_controller.rb` which permits the two attributes to be updated:

    module <wagon_namespace>
      module PeopleController
        extend ActiveSupport::Concern
        included do
          self.permitted_attrs += [:title, :salutation]
        end
      end
    end

#### Show and edit attributes in the view

There are two views which have to be adapted regarding the `Person` model: On one side the show view of the person and on the other side the edit view of the person.

Create a new file in `app/views/people/_details_<wagon_namespace>.html.haml` with the following content:

    = render_attrs(entry, :title, :salutation)

Create a new file in `app/views/people/_fields_<wagon_namespace>.html.haml` with the following content:

    = f.labeled_input_fields :title, :salutation

It is important that these files start with `_details` respectively `_fields`. The core-application automatically includes/renders all files starting with `_details` and `_fields`. The subsequent characters (`_<wagon_namespace>`) can be chosen arbitrarily.

#### Translate the attribute names

In order to display the attribute names properly in each language, the language files of all used languages must be adapted by simply adding the following lines to the `config/locales/models.<wagon_namespace>.<language_code>.yml`-files:

    attributes:
      person:
      title: <translation_for_title_attribute_in_corresponding_language>
      salutation: <translation_for_salutation_attribute_in_corresponding_language>

#### Include attributes in the CSV/Excel Exports

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

#### Make attributes searchable

The new attributes must be indexed in `app/indices/person_index.rb` where all indexes for Sphinx (the search tool that is used by hitobito) are defined.

    ThinkingSphinx::Index.define_partial :person do
      indexes title
    end

#### Output attributes in the API

In order to provide the additional attributes in the API (the JSON-file of the object), the serializer for the people must be extended in `app/serializers/<wagon_namespace>/person_serializer.rb`:

    module <wagon_namespace>::PersonSerializer
      extend ActiveSupport::Concern
      included do
        extension(:details) do |_|
          map_properties :title, :salutation
        end
      end
    end

#### Wire up above extensions

The newly created or updated `PeopleController`, the CSV export file and the serializer file for the API must also be defined in the wagon configuration file which is located in `lib/<wagon_name>/wagon.rb`.

    config.to_prepare do
        ...
        PeopleController.send :include, <wagon_namespace>::PeopleController
        Export::Tabular::People::PeopleAddress.send :include, <wagon_namespace>::Export::Tabular::People::PeopleAddress
        PersonSerializer.send :include, <wagon_namespace>::PersonSerializer
    end

#### Write tests for attributes

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
