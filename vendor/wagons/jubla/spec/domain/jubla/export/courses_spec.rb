require 'spec_helper'
describe Export::Courses do

  let(:person) { Fabricate.build(:person_with_address_and_phone, j_s_number: 123) } 
  let(:advisor) { Fabricate(:person_with_address_and_phone) } 
  let(:course) { Fabricate.build(:course, contact: person, state: :application_open, advisor_id: advisor.id) } 
  let(:row) { Export::Courses::Row.new(course) } 
  
  subject { OpenStruct.new(row.hash) } 

  its(:state) { should eq 'Offen zur Anmeldung' } 
  its(:contact_j_s_number) { should eq 123 } 
  its(:advisor_name) { should eq advisor.to_s }

  
end

