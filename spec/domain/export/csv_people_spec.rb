# encoding: UTF-8
require 'spec_helper'
describe Export::CsvPeople do

  let(:person) { people(:top_leader) } 
  let(:simple_headers) { ["Vorname", "Nachname", "Übername", "Email", "Adresse", "PLZ", "Ort", "Land", "Geburtstag", "Rollen" ] }
  let(:full_headers) { ["Vorname", "Nachname", "Übername", "Email", "Adresse", "PLZ", "Ort", "Land", "Geburtstag", "Firmenname", "Firma", "Rollen" ] }

  describe Export::CsvPeople do

    subject { csv }
    let(:list) { [person] } 
    let(:data) { Export::CsvPeople.export(list) } 
    let(:csv) { CSV.parse(data, headers: true, col_sep: Settings.csv.separator) } 


    context "export" do
      its(:headers) { should eq simple_headers }

      context "first row" do
        
        subject { csv[0] } 

        its(['Vorname']) { should eq person.first_name } 
        its(['Nachname']) { should eq person.last_name } 
        its(['Email']) { should eq person.email } 
        its(['Ort']) { should eq person.town } 
        its(['Rollen']) { should eq "Rolle TopGroup" }
        its(['Geschlecht']) { should be_blank }

        context "roles and phone number" do
          before do 
            Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one), person: person)
            person.phone_numbers.create(label: 'vater', number: 123)
          end

          its(['Telefonnummer Vater']) { should eq '123' }
          its(['Rollen']) { should eq 'Rolle Group 11, Rolle TopGroup' }
        end
      end
    end

    context "export_full" do
      its(:headers) { should eq full_headers }
      let(:data) { Export::CsvPeople.export_full(list) } 

      context "first row" do
        before do 
          person.update_attribute(:gender, 'm')
          person.social_accounts << SocialAccount.new(label: 'skype', name: 'foobar')
          person.phone_numbers << PhoneNumber.new(label: 'vater', number: 123, public: false)
        end

        subject { csv[0] }

        its(['Rollen']) { should eq "Rolle TopGroup" }
        its(['Telefonnummer Vater']) { should eq '123' }
        its(['Skype']) { should eq 'foobar' }
        its(['Geschlecht']) { should be_blank }
      end
    end
  end

  describe Export::CsvPeople::Person do
    subject { Export::CsvPeople::Person.new(person) } 

    context "standard attributes" do
      its([:id]) { should eq person.id }
      its([:first_name]) { should eq 'Top' } 
    end

    context "roles" do
      its([:roles]) { should eq 'Rolle TopGroup' } 

      context "multiple roles" do
        let(:group) { groups(:bottom_group_one_one) }
        before { Fabricate(Group::BottomGroup::Member.name.to_s, group: group, person: person) } 

        its([:roles]) { should eq 'Rolle Group 11, Rolle TopGroup' } 
      end
    end

    context "phone numbers" do
      before { person.phone_numbers << PhoneNumber.new(label: 'foobar', number: 321) }
      its([:phone_number_foobar]) { should eq '321' }
    end

    context "social accounts " do
      before { person.social_accounts << SocialAccount.new(label: 'foobar', name: 'asdf') }
      its([:social_account_foobar]) { should eq 'asdf' } 
    end
  end

  describe "Export::CsvPeople::Associations" do
    subject { Export::CsvPeople::Associations } 

    context "phone_numbers" do 
      it "creates standard key and human translations" do
        subject.phone_numbers.key('foo').should eq :phone_number_foo
        subject.phone_numbers.human('foo').should eq 'Telefonnummer Foo'
      end
    end

    context "social_accounts" do 
      it "creates standard key and human translations" do
        subject.social_accounts.key('foo').should eq :social_account_foo
        subject.social_accounts.human('foo').should eq 'Foo'
      end
    end
  end


  describe Export::CsvPeople::People do
    let(:list) { [person] } 
    let(:people_list) { Export::CsvPeople::People.new(list) }
    subject { people_list } 

    its(:attributes) { should eq [:first_name, :last_name, :nickname, :email, :address, 
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

  describe Export::CsvPeople::PeopleFull do
    let(:list) { [person] } 
    let(:people_list) { Export::CsvPeople::PeopleFull.new(list) }
    subject { people_list } 

    its([:roles]) { should eq 'Rollen' }
    its(:attributes) { should eq [:first_name, :last_name, :nickname, :email, :address, 
                                  :zip_code, :town, :country, :birthday, :company_name, :company] }

    its([:social_account_website]) { should be_blank } 

    its([:company]) { should eq 'Firma' } 
    its([:company_name]) { should eq 'Firmenname' } 

    context "social accounts" do
      before { person.social_accounts << SocialAccount.new(label: 'Webseite', name: 'foo.bar') }
      its([:social_account_webseite]) { should eq 'Webseite' } 
    end
  end

end
