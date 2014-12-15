# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe Import::PersonImporter do
  include CsvImportMacros

  let(:group) { groups(:top_group) }
  let(:role_type) { Group::TopGroup::Leader }
  let(:importer)  { Import::PersonImporter.new(data, group, role_type)  }
  subject { importer }

  context 'minimal' do
    let(:data) { [{ first_name: 'foo' }] }

    it 'creates person' do
      expect { subject.import }.to change(Person, :count).by(1)
    end

    it 'creates role' do
      expect { subject.import }.to change(Role, :count).by(1)
    end
  end

  context 'creates associations' do
    let(:data) { [{ first_name: 'foo', social_account_skype: 'foobar', phone_number_vater: '0123' }] }

    it 'creates person' do
      expect { subject.import }.to change(SocialAccount, :count).by(1)
    end

    it 'creates role' do
      expect { subject.import }.to change(PhoneNumber, :count).by(1)
    end
  end

  context 'records successful and failed imports' do
    let(:data) { [{ first_name: 'foobar', email: 'foo@bar.net' },  { first_name: 'foobar', zip_code: 'asdf' }] }

    it 'creates only first record' do
      expect { subject.import }.to change(Person, :count).by(1)
    end

    context 'result' do
      before { importer.import }
      its(:new_count)  { should eq 1 }
      its(:failure_count)  { should eq 1 }
    end

    context 'base error' do
      let(:data) { [{}] }
      before { importer.import }
      its('errors.first') { should eq 'Zeile 1: Bitte geben Sie einen Namen ein.' }
    end

    context 'zip_code validation' do
      before { importer.import }
      its('errors.first') { should eq 'Zeile 2: PLZ ist keine Zahl' }
    end
  end

  context 'duplicate emails' do
    let(:emails) { ['foo@bar.com', '', nil, 'bar@foo.com', 'foo@bar.com'] }
    let(:data) { emails.map { |email| Fabricate.build(:person, email: email).attributes.select { |attr| attr =~ /name|email/ } } }
    before { importer.import }
    its(:errors) { should have(1).item }
    its('errors.last') { should start_with 'Zeile 5: Haupt-E-Mail ist bereits vergeben' }
  end

  context 'doublettes' do
    let(:attrs) { { first_name: 'foobar', email: 'foo@bar.net' } }
    let(:data) { [attrs.merge(email: 'bar@foo.net')] }
    let(:person) { @person.reload }

    before { @person = Fabricate(:person, attrs) }
    subject { person }


    context 'adds role, does not update email' do
      before { importer.import }
      its(:email) { should eq 'foo@bar.net' }
      its('roles.size') { should eq 1 }
      it 'updates double and success count' do
        importer.doublette_count.should eq 1
        importer.new_count.should eq 0
      end
    end

    context 'does not duplicate role' do
      before do
        role = person.roles.new
        role.group = group
        role.type = role_type.sti_name
        role.save!
        importer.import
        person.reload
      end
      its(:email) { should eq 'foo@bar.net' }
      its('roles.size') { should eq 1 }
    end

    context 'marks multiple' do
      before { Fabricate(:person, attrs.merge(email: 'asdf@asdf.net')); importer.import }
      subject { importer }
      its(:errors) { should eq ['Zeile 1: 2 Treffer in Duplikatserkennung.'] }
      it 'does not change person' do
        person.reload.roles.size.should eq 0
      end
    end

    context 'person loaded multiple times via doublette finder' do
      let(:attrs) { { email: 'foo@bar.net', nickname: '', last_name: '' } }
      let(:data) do [{ email: 'foo@bar.net', nickname: 'nickname', town: 'Bern', social_account_msn: 'msn' },
                     { email: 'foo@bar.net', last_name: 'last_name', town: 'Muri', social_account_skype: 'skype' }] end

      before { importer.import }
      its('roles.size') { should eq 1 }
      its(:nickname) { should eq 'nickname' }
      its(:last_name) { should eq 'last_name' }
      its(:town) { should eq 'Bern' }
      its('social_accounts.size') { should eq 2 }
    end
  end

  context 'list file' do
    let(:parser) { Import::CsvParser.new(File.read(path(:list))) }
    let(:mapping) { headers_mapping(parser) }
    let(:data) { parser.map_data(mapping) }
    let(:imported) { Person.order(:id).last }

    before { parser.parse }

    context 'importer reports errors' do
      before { importer.import }
      subject { importer }

      its(:errors) { should include 'Zeile 1: Firmenname muss ausgefüllt werden' }
      its(:errors) { should include 'Zeile 2: Firmenname muss ausgefüllt werden, PLZ ist keine Zahl' }
      its(:errors) { should include 'Zeile 4: PLZ ist keine Zahl' }
      its(:errors) { should have(3).items }
    end

    context 'imported person' do
      before { expect { importer.import }.to change { Person.count }.by(1) }
      subject { imported }

      its(:first_name) { should eq 'Ramiro' }
      its(:last_name) { should eq 'Brown' }
      its(:additional_information) { should be_present }
      its(:company) { should eq false }
      its(:company_name) { should eq 'Oda Cormier' }
      its(:email) { should eq 'ramiro_brown@example.com' }
      its(:address) { should eq '1649 Georgette Circles' }
      its(:zip_code) { should eq 72_026 }
      its(:town) { should be_blank }
      its(:gender) { should eq 'm' }
      its(:additional_information) { should be_present }

      context 'phone numbers' do
        subject { imported.phone_numbers }
        its(:size) { should eq 4 }
        its('first.label') { should eq 'Privat' }
        its('first.number') { should eq '1-637-999-2837 x7851' }

        its('second.label') { should eq 'Mobil' }
        its('second.label') { should eq 'Mobil' }

        its('third.label') { should eq 'Arbeit' }
        its('third.number') { should eq '1-403-4ä9-5561' }

        its('fourth.label') { should eq 'Vater' }
        its('fourth.number') { should eq '908.647.4334' }
      end

      context 'social accounts' do
        subject { imported.social_accounts.order(:label) }
        its(:size) { should eq 3 }
        its('first.label') { should eq 'MSN' }
        its('first.name') { should eq 'reyes_mckenzie' }

        its('second.label') { should eq 'Skype' }
        its('second.name') { should eq 'florida_armstrong' }

        its('third.label') { should eq 'Webseite' }
        its('third.name') { should eq 'colliäs.com' }
      end
    end
  end

end
