require 'spec_helper'
describe Export::Courses do

  let(:person) { Fabricate.build(:person_with_address_and_phone, j_s_number: 123) }
  let(:advisor) { Fabricate(:person_with_address_and_phone, j_s_number: 123) }
  let(:course) { Fabricate.build(:course, contact: person, state: :application_open, advisor_id: advisor.id) }
  let(:contactable_keys) { [:name, :address, :zip_code, :town, :email, :phone_numbers, :j_s_number] }

  context Export::Courses::JublaList do

    context "used labels" do
      let(:list) { Export::Courses::JublaList.new(double("courses", map: [])) }
      subject { list.labels }

      its(:keys) { should include(*[:advisor_name, :advisor_address, :advisor_zip_code, :advisor_town, :advisor_email, :advisor_phone_numbers]) }
      its(:values) { should include(*["LKB Name", "LKB Adresse", "LKB PLZ", "LKB Ort", "LKB E-Mail", "LKB Telefonnummern"]) }
    end
  end

  context Export::Courses::JublaRow do
    let(:list) { OpenStruct.new(max_dates: 3, contactable_keys: contactable_keys) }
    let(:row) { Export::Courses::JublaRow.new(course, list) }
    
    subject { OpenStruct.new(row.hash) }

    its(:state) { should eq 'Offen zur Anmeldung' }
    its(:contact_j_s_number) { should eq 123 }
    its(:advisor_name) { should eq advisor.to_s }
    its(:advisor_j_s_number) { should eq "123" } # varchar in db
  end
    
end

