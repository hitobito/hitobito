# encoding: UTF-8
require 'spec_helper'
describe Export::CsvPeople do
  let(:person) { people(:top_leader) } 

  let(:simple_headers) { ["Vorname", "Nachname", "Übername", "Email", "Adresse", "PLZ", "Ort", "Land", "Geburtstag", "Rollen", 
                          "Telefonnummer Privat", "Telefonnummer Mobil", "Telefonnummer Arbeit", "Telefonnummer Vater", "Telefonnummer Mutter", 
                          "Telefonnummer Fax", "Telefonnummer Andere"] } 

  let(:full_headers)   { ["Vorname", "Nachname", "Übername", "Email", "Adresse", "PLZ", "Ort", "Land", "Geburtstag",
                          "Firmenname", "Firma", "Geschlecht", "Zusätzliche Angaben", "Rollen",
                          "Telefonnummer Privat", "Telefonnummer Mobil", "Telefonnummer Arbeit", "Telefonnummer Vater", "Telefonnummer Mutter", 
                          "Telefonnummer Fax", "Telefonnummer Andere",
                          "Social Media Adresse Skype", "Social Media Adresse Webseite", "Social Media Adresse MSN" ] }

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
        its(['Social Media Adresse Skype']) { should eq 'foobar' }
        its(['Geschlecht']) { should eq 'm' }
      end
    end

  end

  describe Export::CsvPeople::Simple do
    let(:export) { Export::CsvPeople::Simple.new(person) } 
    subject { Export::CsvPeople::Simple } 

    its(:headers) { should eq  [:first_name, :last_name, :nickname, :email, :address, :zip_code, :town, :country, 
                                :birthday, :roles, :phone_number_privat, :phone_number_mobil, :phone_number_arbeit,
                                :phone_number_vater, :phone_number_mutter, :phone_number_fax, :phone_number_andere] }

    its(:translated_headers) { should eq simple_headers } 

    it "#hash has data prepared for export" do
      export.hash.should eq first_name: "Top", last_name: "Leader", nickname: nil, 
        email: "top_leader@example.com", address: nil, zip_code: nil,
        town: "Supertown", country: nil, birthday: nil, roles: "Rolle TopGroup" 
    end

    context "roles are comma separated list" do
      subject { export.hash }
      before { Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one), person: person) } 
      its([:roles]) { should eq "Rolle Group 11, Rolle TopGroup" } 
    end 

    context "phone numbers are seperate fields" do
      before do
        person.phone_numbers << PhoneNumber.new(label: 'vater', number: 123)
        person.phone_numbers << PhoneNumber.new(label: 'mobil', number: 321)
        person.phone_numbers << PhoneNumber.new(label: 'privat', number: 321, public: false)
      end

      subject { export.hash }
      
      its([:phone_number_vater]) { should eq '123' } 
      its([:phone_number_mobil]) { should eq '321' } 
      its([:phone_number_privat]) { should be_nil } 
      its(:keys) { should_not include :phone_number_privat  } 
    end
  end

  describe Export::CsvPeople::Full do
    let(:export) { Export::CsvPeople::Full.new(person) } 
    subject { Export::CsvPeople::Full } 

    its(:headers) { should eq  [:first_name, :last_name, :nickname, :email, :address, :zip_code, :town, :country, 
                                :birthday, :company_name, :company, :gender, :additional_information, :roles,
                                :phone_number_privat, :phone_number_mobil, :phone_number_arbeit,
                                :phone_number_vater, :phone_number_mutter, :phone_number_fax, :phone_number_andere,
                                :social_account_skype, :social_account_webseite, :social_account_msn] }

    its(:translated_headers) { should eq full_headers } 

    context "exports additional fields" do
      before do
        person.update_attribute(:gender, 'm')
        person.phone_numbers << PhoneNumber.new(label: 'privat', number: 321, public: false)
        person.social_accounts << SocialAccount.new(label: 'skype', name: 'foobar')
      end

      subject { export.hash }
      
      its([:phone_number_privat]) { should eq '321' } 
      its([:social_account_skype]) { should eq 'foobar' } 
      its([:gender]) { should eq 'm' } 
    end
  end
  
end
