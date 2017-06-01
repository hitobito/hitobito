## Adding Attributes to People Class

The following steps must be performed when adding new attributes to a model in hitobito:

### Add new attributes to the model

The following documentation describes how new attributes can be added to a model in the hitobito application. For reasons of simplification, this documentation follows an example where the generic wagon is going to be adapted and the 'people'-model gets two new attributes called 'title' and 'salutation'.

In order to adapt the database structure and add the desired new attributes to the model, a new migration must be created by the following command:

    $bin/rails generate migration AddPeopleAttrs

This command will create a new migration file in the path `/db/migrate/YYYYMMDDHHMMSS_add_people_attrs.rb` which in the end should look as follows:

    class AddPeopleAttrs < ActiveRecord::Migration
        def change
            add_column :people, :title, :string
            add_column :people, :salutation, :string
        end
    end

In this example, the datatypes of the attributes are set to strings.

### Add new attributes to the controller

The new attributes must be included in the application logic. To do so, a new controller has to be created in `/app/controllers/<new_namespace>/people_controller.rb` which sets the two attributes as 'permitted':

    module <new_namespace>
        module PeopleController
            extend ActiveSupport::Concern
            included do
                self.permitted_attrs += [:title, :salutation]
            end
        end
    end

### Add new attributes to the views

There are two views which have to be adapted regarding the people model: On one side the 'show'-view of the person and on the other side the 'edit'-view of the person.

#### Show View

Create a new file in `/app/views/people/_details_<new_namespace>.html.haml` with the following content:

    render_attrs(entry, :title, :salutation)

#### Edit View

Create a new file in `/app/views/people/_fields_<new_namespace>.html.haml` with the following content:

    f.labeled_input_fields :title, :salutation

It is important that these files start with _details respectively _fields. The core-application automatically includes/renders all files starting with _details and _fieds. The subsequent characters (`_<new_namespace>`) can be chosen arbitrarily.

### Translation-Files

In order to display the attribute names properly in each language, the language files of all used languages must be adapted by simply adding the following lines to the `/config/locales/models.generic.<language_code>.yml`-files:

    attributes:
        person:
        title: <translation_for_title_attribute_in_corresponding_language>
        salutation: <translation_for_salutation_attribute_in_corresponding_language>

### Include new attributes in the CSV-Export

If wished, the attributes can be included in the CSV-File that is generated when performing a contact export. For this inclusion, a new file in `app/domain/<new_namespace>/export/csv/people/people_address.rb` with the following content must be created:

    module <new_namespace>
        module Export
            module Csv
                module People
                    module PeopleAddress
                        extend ActiveSupport::Concern
                        included do
                            alias_method_chain :person_attributes, :title
                        end
                        def person_attributes_with_title
                            person_attributes_without_title 
                            [:title, :salutation]
                        end
                    end
                end
            end
        end
    end

### Make new attributes available in the search

The new attributes must be indexed in `/app/indices/person_index.rb` where all indexes for Sphinx (the search tool that is used by hitobito) are defined .

    ThinkingSphinx::Index.define_partial :person do
      indexes title
    end

### Make new attributes available in the API

In order to provide the additional attributes in the API (the JSON-file of the object), the serializer of the people-model must be extended in `/app/serializers/<new_namespace>/person_serializer.rb`:

    module <new_namespace>::PersonSerializer
        extend ActiveSupport::Concern
        included do
            extension(:details) do |_|
                map_properties :title, :salutation
            end
        end
    end

### Configuraton of wagon-file

The newly created or updated people-controller, the CSV-export-file and the serializer-file for the API must also be defined in the wagon-file which is located in /lib/<wagon_name>/wagon.rb

    config.to_prepare do
        ...
        PeopleController.send :include, <new_namespace>::PeopleController
        Export::Csv::People::PeopleAddress.send :include, <new_namespace>::Export::Csv::People::PeopleAddress
        PersonSerializer.send :include, <new_namespace>::PersonSerializer
    end

### Writing tests for new attributes

Arbitrary tests cases can be defined in the `/spec/` directory of the wagon. As an example, the following file (`/spec/domain/export/csv/people_spec.rb`) proposes a test case that checks whether the attributes are exported properly into the CSV-file:

    require 'spec_helper'
    require 'csv'

    describe Export::Csv::People do
        let(:person) { people(:admin) }
        let(:simple_headers) do
            %w(Vorname Nachname Übername Firmenname Firma Haupt-E-Mail Adresse PLZ Ort Land Geschlecht Geburtstag Rollen Titel Anrede)
        end

        let(:list) { Person.where(id: person) }
        let(:data) { Export::Csv::People::PeopleAddress.export(list) }
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
            let(:data) { Export::Csv::People::PeopleFull.export(list) }

            context 'first row' do
                subject { csv[0] }
                its(['Titel']) { should eq 'Dr.' }
                its(['Anrede']) { should eq 'Herr' }
            end
        end
    end