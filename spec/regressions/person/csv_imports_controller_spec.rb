#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "csv"
describe Person::CsvImportsController, type: :controller do
  include CsvImportMacros

  render_views
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }

  before { sign_in(person) }

  subject { Capybara::Node::Simple.new(response.body) }

  describe "GET :new" do
    it "renders template" do
      get :new, params: {group_id: group.id}
      is_expected.to render_template(:new)
      is_expected.to have_content "Personen über CSV importieren"
    end
  end

  describe "POST :define_mapping" do
    it "renders template and flash" do
      file = Rack::Test::UploadedFile.new(path(:utf8), "text/csv")
      post :define_mapping, params: {group_id: group.id, csv_import: {file: file}}
      is_expected.to render_template(:define_mapping)
      is_expected.to have_content "1 Datensatz erfolgreich gelesen."
      is_expected.to have_content "Rolle auswählen"
      is_expected.to have_content "Spalten zu Feldern zuordnen"
      expect(subject.find_field("Vorname").find("option[selected]").text).to eq "Vorname"
    end
  end

  describe "POST :create imports single person" do
    let(:data) { File.read(path(:list)) }
    let(:role_type) { Group::TopGroup::Leader }
    let(:mapping) { headers_mapping(CSV.parse(data, headers: true)) }

    it "imports single person only" do
      expect { post :create, params: {group_id: group.id, data: data, role_type: role_type.sti_name, field_mappings: mapping} }.to change(Person, :count).by(1)
      is_expected.to redirect_to group_people_path(group, name: "Leader", filters: {role: {role_type_ids: [role_type.id]}})
    end
  end

  describe "POST :preview renders preview" do
    let(:data) { File.read(path(:list)) }
    let(:role_type) { "Group::TopGroup::Leader" }
    let(:mapping) { headers_mapping(CSV.parse(data, headers: true)).merge(role: role_type) }

    it "imports single person only" do
      expect { post :preview, params: {group_id: group.id, data: data, role_type: role_type, field_mappings: mapping} }.not_to change(Person, :count)
      is_expected.to have_css "table"
      is_expected.to have_button "Personen jetzt importieren"
      is_expected.to have_button "Zurück"
    end
  end
end
