# encoding: UTF-8
require 'spec_helper'
describe CsvImportsController, type: :controller do
  include CsvImportMacros

  render_views
  let(:group) { groups(:top_group) } 
  let(:person) { people(:top_leader) } 
  before { sign_in(person) } 
  subject { Capybara::Node::Simple.new(response.body) } 


  describe "GET :new" do
    it "renders template" do
      get :new, group_id: group.id
      should render_template(:new)
      should have_content 'Personen über CSV importieren'
    end
  end


  describe "POST :define_mapping" do
    it "renders template and flash" do
      file = Rack::Test::UploadedFile.new(path(:utf8), "text/csv") 
      post :define_mapping, group_id: group.id, csv_import: { file: file } 
      should render_template(:define_mapping)
      should have_content '1 Datensatz erfolgreich gelesen.'
      should have_content 'Rolle festlegen'
      should have_content 'Attribut Zuordnung festlegen'
    end
  end

end
