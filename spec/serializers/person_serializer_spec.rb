# encoding: utf-8
# == Schema Information
#
# Table name: people
#
#  id                        :integer          not null, primary key
#  first_name                :string(255)
#  last_name                 :string(255)
#  company_name              :string(255)
#  nickname                  :string(255)
#  company                   :boolean          default(FALSE), not null
#  email                     :string(255)
#  address                   :string(1024)
#  zip_code                  :string(255)
#  town                      :string(255)
#  country                   :string(255)
#  gender                    :string(1)
#  birthday                  :date
#  additional_information    :text(65535)
#  contact_data_visible      :boolean          default(FALSE), not null
#  created_at                :datetime
#  updated_at                :datetime
#  encrypted_password        :string(255)
#  reset_password_token      :string(255)
#  reset_password_sent_at    :datetime
#  remember_created_at       :datetime
#  sign_in_count             :integer          default(0)
#  current_sign_in_at        :datetime
#  last_sign_in_at           :datetime
#  current_sign_in_ip        :string(255)
#  last_sign_in_ip           :string(255)
#  picture                   :string(255)
#  last_label_format_id      :integer
#  creator_id                :integer
#  updater_id                :integer
#  primary_group_id          :integer
#  failed_attempts           :integer          default(0)
#  locked_at                 :datetime
#  authentication_token      :string(255)
#  show_global_label_formats :boolean          default(TRUE), not null
#  household_key             :string(255)
#

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PeopleSerializer do

  let(:person) do
    p = people(:top_leader)
    Fabricate(:additional_email, contactable: p, public: true)
    Fabricate(:social_account, contactable: p, public: true)
    Fabricate(:social_account, contactable: p, public: false)
    p.decorate
  end

  let(:controller) { double().as_null_object }

  let(:serializer) { PersonSerializer.new(person, controller: controller)}
  let(:hash) { serializer.to_hash }

  subject { hash[:people].first }

  let(:user) { Person.first }

  context 'with details' do
    before { allow(controller).to receive(:can?).and_return(true) }

    it 'has additional properties' do
      is_expected.to have_key(:birthday)
      is_expected.to have_key(:gender)
    end

    it 'has all accounts' do
      links = subject[:links]
      expect(links[:social_accounts].size).to eq(2)
      expect(links[:additional_emails].size).to eq(1)
      expect(links).not_to have_key(:phone_numbers)
    end

    it 'does not contain login credentials' do
      is_expected.not_to have_key(:password)
      is_expected.not_to have_key(:encrypted_password)
      is_expected.not_to have_key(:authentication_token)
    end
  end

  context 'without details' do
    before { allow(controller).to receive(:can?).and_return(false) }

    it 'has additional properties' do
      is_expected.not_to have_key(:birthday)
      is_expected.not_to have_key(:gender)
    end

    it 'has only public accounts' do
      links = subject[:links]
      expect(links[:social_accounts].size).to eq(1)
      expect(links[:additional_emails].size).to eq(1)
      expect(links).not_to have_key(:phone_numbers)
    end

    it 'contains correct household key' do
      is_expected.to have_key(:household_key)
    end

    it 'has null household key' do
      household_key = subject[:household_key]
      expect(household_key).to eq(nil)
    end

    it 'uses same household key if same household' do
      other = people(:top_leader).decorate
      person.update(household_key: "1")
      Person::Household.new(person, Ability.new(person), other).tap(&:assign)
      serial_person = PersonSerializer.new(person, controller: controller).to_hash[:people]
      serial_other = PersonSerializer.new(other, controller: controller).to_hash[:people]
      expect(serial_other.first[:household_key]).not_to eq(nil)
      expect(serial_person.first[:household_key]).to eq(serial_other.first[:household_key])
    end

  end

end
