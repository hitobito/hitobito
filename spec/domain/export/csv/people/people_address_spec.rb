# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
require 'csv'

describe Export::Csv::People::PeopleAddress do

  let(:person) { people(:top_leader) }
  let(:list) { [person] }
  let(:people_list) { Export::Csv::People::PeopleAddress.new(list) }
  subject { people_list }

  its(:attributes) do
    should == [:first_name, :last_name, :nickname, :company_name, :company, :email, :address,
               :zip_code, :town, :country, :gender, :birthday, :roles]
  end

  context 'standard attributes' do

    context '#attribute_labels' do
      subject { people_list.attribute_labels }

      its([:id]) { should be_blank }
      its([:roles]) { should eq 'Rollen' }
      its([:first_name]) { should eq 'Vorname' }
    end

    context 'key list' do
      subject { people_list.attribute_labels.keys.join(' ') }
      it { should_not =~ /phone/ }
      it { should_not =~ /social_account/ }
    end
  end

  context 'phone_numbers' do
    before { person.phone_numbers << PhoneNumber.new(label: 'Privat', number: 321) }

    subject { people_list.attribute_labels }

    its([:phone_number_privat]) { should eq 'Telefonnummer Privat' }
    its([:phone_number_mobil]) { should be_nil }

    context 'different labels' do
      let(:other) { people(:bottom_member) }
      let(:list) { [person, other] }

      before do
        other.phone_numbers << PhoneNumber.new(label: 'Foobar', number: 321)
        person.phone_numbers << PhoneNumber.new(label: 'Privat', number: 321)
      end

      its([:phone_number_privat]) { should eq 'Telefonnummer Privat' }
      its([:phone_number_foobar]) { should eq 'Telefonnummer Foobar' }
    end

    context 'blank label is not exported' do
      before { person.phone_numbers << PhoneNumber.new(label: '', number: 321) }
      its(:keys) { should_not include :phone_number_ }
    end
  end

  context 'integration' do
      let(:simple_headers) do
        ['Vorname', 'Nachname', 'Übername', 'Firmenname', 'Firma', 'Haupt-E-Mail',
         'Adresse', 'PLZ', 'Ort', 'Land', 'Geschlecht', 'Geburtstag', 'Rollen']
      end
      let(:data) { Export::Csv::People::PeopleAddress.export(list) }
      let(:csv) { CSV.parse(data, headers: true, col_sep: Settings.csv.separator) }

      subject { csv }

      its(:headers) { should == simple_headers }

      context 'first row' do

        subject { csv[0] }

        its(['Vorname']) { should eq person.first_name }
        its(['Nachname']) { should eq person.last_name }
        its(['Haupt-E-Mail']) { should eq person.email }
        its(['Ort']) { should eq person.town }
        its(['Geschlecht']) { should be_blank }

        context 'roles and phone number' do
          before do
            Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one), person: person)
            person.phone_numbers.create!(label: 'vater', number: 123)
            person.additional_emails.create!(label: 'Vater', email: 'vater@example.com')
            person.additional_emails.create!(label: 'Mutter', email: 'mutter@example.com', public: false)
          end

          its(['Telefonnummer Vater']) { should eq '123' }
          its(['Weitere E-Mail Vater']) { should eq 'vater@example.com' }
          its(['Weitere E-Mail Mutter']) { should be_nil }

          it 'roles should be complete' do
            subject['Rollen'].split(', ').should =~ ['Member Bottom One / Group 11', 'Leader Top / TopGroup']
          end
        end
      end
  end

end
