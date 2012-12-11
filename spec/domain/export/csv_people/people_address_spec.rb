require 'spec_helper'

describe Export::CsvPeople::PeopleAddress do
  
  let(:person) { people(:top_leader) }
  let(:list) { [person] }
  let(:people_list) { Export::CsvPeople::PeopleAddress.new(list) }
  subject { people_list }

  its(:attributes) { should == [:first_name, :last_name, :nickname, :company_name, :company, :email, :address,
                                :zip_code, :town, :country, :birthday] }

  context "standard attributes" do
    its([:id]) { should be_blank }
    its([:roles]) { should eq 'Rollen' }
    its([:first_name]) { should eq 'Vorname' }

    context "key list" do
      subject { people_list.keys.join(' ') }
      it { should_not =~ /phone/ }
      it { should_not =~ /social_account/ }
    end
  end

  context "phone_numbers" do
    before { person.phone_numbers << PhoneNumber.new(label: 'Privat', number: 321) }

    its([:phone_number_privat]) { should eq 'Telefonnummer Privat' }
    its([:phone_number_mobil]) { should be_nil }

    context "different labels" do
      let(:other) { people(:bottom_member) }
      let(:list) { [person, other] }

      before do
        other.phone_numbers << PhoneNumber.new(label: 'Foobar', number: 321)
        person.phone_numbers << PhoneNumber.new(label: 'Privat', number: 321)
      end

      its([:phone_number_privat]) { should eq 'Telefonnummer Privat' }
      its([:phone_number_foobar]) { should eq 'Telefonnummer Foobar' }
    end
  end
end