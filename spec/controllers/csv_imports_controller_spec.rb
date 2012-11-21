# encoding: UTF-8
require 'spec_helper'
require 'csv'

describe CsvImportsController do
  include CsvImportMacros
  let(:group) { groups(:top_group) } 
  let(:person) { people(:top_leader) } 
  before { sign_in(person) } 


  describe "POST #define_mapping" do

    it "populates flash, data and columns" do
      file = Rack::Test::UploadedFile.new(path(:utf8), "text/csv") 
      post :define_mapping, group_id: group.id, csv_import: { file: file } 
      flash[:data].should be_present
      flash[:columns].should be_present
      flash[:notice].should =~ /1 Datensatz erfolgreich gelesen/
    end

    it "redisplays form if failed to parse csv" do
      file = Rack::Test::UploadedFile.new(path(:utf8,:ods),"text/csv") 
      post :define_mapping, group_id: group.id, csv_import: { file: file } 
      flash[:data].should_not be_present
      flash[:alert].should =~ /Fehler beim Lesen von utf8.ods/
      should redirect_to new_group_csv_imports_path
    end
  end
  
  describe "POST #create" do
    let(:data) { File.read(path(:utf8)) } 
    let(:role_type) { "Group::TopGroup::Leader" }
    let(:mapping) { { Vorname: 'first_name', Nachname: 'last_name', Geburtsdatum: 'birthday', role: role_type } }

    it "populates flash and redirects to group role list" do
      expect { post :create, group_id: group.id, data: data, csv_import: mapping }.to change(Person,:count).by(1)
      flash[:notice].should eq ["1 Person(Rolle) wurden erfolgreich importiert."]
      flash[:alert].should_not be_present
      should redirect_to group_people_path(group, role_types: role_type, name: "Rolle")
    end

    context "bad phone number" do
      let(:mapping) { { Vorname: 'first_name', Telefon: 'phone_number_vater', role: role_type } }
      let(:data) do
        CSV.generate do |csv| 
          csv << %w{Vorname Telefon}
          csv << %w{foo }
        end
      end 
        
      it "imports first person and displays errors for second person" do
        expect { post :create, group_id: group.id, data: data, csv_import: mapping }.to change(Person,:count).by(0)
        flash[:alert].should eq ["1 Person(Rolle) konnten nicht importiert werden.", 
                                 "Zeile 1: Telefonnummer muss ausgefüllt werden"]
        should redirect_to group_people_path(group, role_types: role_type, name: "Rolle")
      end
    end

  end
end
