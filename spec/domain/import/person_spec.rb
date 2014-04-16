# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe Import::Person do

  context 'keys' do
    subject { Import::Person.fields.map { |entry| entry[:key] }  }
    it 'contains social media' do
      should include('social_account_skype')
    end

    it 'contains phone number' do
      should include('phone_number_vater')
    end

    it 'contains additional email' do
      should include('additional_email_vater')
    end
  end

  context 'labels' do
    subject { Import::Person.fields.map { |entry| entry[:value] }  }

    it 'contains social media' do
      should include('Social Media Adresse Skype')
    end

    it 'contains phone number' do
      should include('Telefonnummer Mutter')
    end

    it 'contains additional email' do
      should include('Weitere E-Mail Mutter')
    end
  end

  context 'extract phone numbers' do
    let(:data) do
      { first_name: 'foo',
        social_account_skype: 'foobar',
        phone_number_vater: '0123',
        additional_email_mutter: 'mutter@example.com' }
    end
    subject { Import::Person.new(data, []).person }

    its(:first_name) { should eq 'foo' }
    its('phone_numbers.first') { should be_present }
    its('phone_numbers.first.label') { should eq 'Vater' }
    its('phone_numbers.first.number') { should eq '0123' }

    its('social_accounts.first') { should be_present }
    its('social_accounts.first.label') { should eq 'Skype' }
    its('social_accounts.first.name') { should eq 'foobar' }

    its('additional_emails.first') { should be_present }
    its('additional_emails.first.label') { should eq 'Mutter' }
    its('additional_emails.first.email') { should eq 'mutter@example.com' }
  end

  context 'keep existing contact accounts' do
    before do
      p = Fabricate(:person, email: 'foo@example.com')
      p.phone_numbers.create!(number: '123', label: 'Privat')
      p.phone_numbers.create!(number: '456', label: 'Mobil')
      p.social_accounts.create!(name: 'foo', label: 'Skype')
      p.social_accounts.create!(name: 'foo', label: 'MSN')
      p.additional_emails.create!(email: 'foo@example.com', label: 'Mutter')
      p.additional_emails.create!(email: 'bar@example.com', label: 'Vater')
    end

    let(:data) do
       { first_name: 'foo',
         email: 'foo@example.com',
         social_account_skype: 'foo',
         social_account_msn: 'bar',
         phone_number_mobil: '123',
         additional_email_mutter: 'bar@example.com',
         additional_email_privat: 'privat@example.com' }
    end

    subject { Import::Person.new(data, []).person }

    its('phone_numbers.first.label') { should eq 'Privat' }
    its('phone_numbers.first.number') { should eq '123' }
    its('phone_numbers.second.label') { should eq 'Mobil' }
    its('phone_numbers.second.number') { should eq '456' }

    its('social_accounts.first.label') { should eq 'Skype' }
    its('social_accounts.first.name') { should eq 'foo' }
    its('social_accounts.second.label') { should eq 'MSN' }
    its('social_accounts.second.name') { should eq 'foo' }
    its('social_accounts.third.label') { should eq 'Msn' }
    its('social_accounts.third.name') { should eq 'bar' }

    its('additional_emails.first.label') { should eq 'Mutter' }
    its('additional_emails.first.email') { should eq 'foo@example.com' }
    its('additional_emails.second.label') { should eq 'Vater' }
    its('additional_emails.second.email') { should eq 'bar@example.com' }
    its('additional_emails.third.label') { should eq 'Privat' }
    its('additional_emails.third.email') { should eq 'privat@example.com' }
  end


  context 'can assign mass assigned attributes' do
    let(:data) { 'all attributes - blacklist' }
    let(:person) { Fabricate(:person) }
    it 'all protected attributes are filtered via blacklist' do
      public_attributes = person.attributes.reject { |key, value| Import::Person::BLACKLIST.include?(key.to_sym) }
      public_attributes.size.should eq 13
      expect { Import::Person.new(public_attributes, []).person }.not_to raise_error
    end
  end


  context 'tracks emails' do
    let(:emails) { ['foo@bar.com', '', nil, 'bar@foo.com', 'foo@bar.com'] }

    let!(:people) do
      emails_tracker = []
      emails.map do |email|
        person = Fabricate.build(:person, email: email).attributes.select { |attr| attr =~ /name|email/ }
        Import::Person.new(person, emails_tracker)
      end
    end

    it 'validates uniquness of emails in currently imported person set' do
      people.first.should be_valid
      people.second.should be_valid
      people.third.should be_valid
      people.fourth.should be_valid
      people.fifth.should_not be_valid
      people.fifth.human_errors.should start_with 'Haupt-E-Mail ist bereits vergeben'
    end
  end


end
