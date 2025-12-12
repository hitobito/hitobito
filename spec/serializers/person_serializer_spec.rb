# frozen_string_literal: true

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
require "spec_helper"

describe PeopleSerializer do
  include Households::SpecHelper

  let(:person) do
    p = people(:top_leader)
    Fabricate(:additional_email, contactable: p, public: true)
    Fabricate(:social_account, contactable: p, public: true)
    Fabricate(:social_account, contactable: p, public: false)
    p.decorate
  end

  let(:controller) { double.as_null_object }

  let(:serializer) { PersonSerializer.new(person, controller: controller) }
  let(:hash) { serializer.to_hash }

  subject { hash[:people].first }

  let(:user) { Person.first }

  context "with details" do
    before { allow(controller).to receive(:can?).and_return(true) }

    it "has additional properties" do
      is_expected.to have_key(:birthday)
      is_expected.to have_key(:gender)
    end

    it "has all accounts" do
      links = subject[:links]
      expect(links[:social_accounts].size).to eq(2)
      expect(links[:additional_emails].size).to eq(1)
      expect(links).not_to have_key(:phone_numbers)
    end

    it "does not contain login credentials" do
      is_expected.not_to have_key(:password)
      is_expected.not_to have_key(:encrypted_password)
      is_expected.not_to have_key(:authentication_token)
    end
  end

  context "without details" do
    include Households::SpecHelper

    before { allow(controller).to receive(:can?).and_return(false) }

    it "has additional properties" do
      is_expected.not_to have_key(:birthday)
      is_expected.not_to have_key(:gender)
    end

    it "has only public accounts" do
      links = subject[:links]
      expect(links[:social_accounts].size).to eq(1)
      expect(links[:additional_emails].size).to eq(1)
      expect(links).not_to have_key(:phone_numbers)
    end

    it "contains correct household key" do
      is_expected.to have_key(:household_key)
    end

    it "has null household key" do
      household_key = subject[:household_key]
      expect(household_key).to eq(nil)
    end

    it "uses same household key if same household" do
      other = people(:bottom_member)
      create_household(person, other)
      serial_person = PersonSerializer.new(person.reload.decorate,
        controller: controller).to_hash[:people]
      serial_other = PersonSerializer.new(other.reload.decorate,
        controller: controller).to_hash[:people]
      expect(serial_other.first[:household_key]).not_to eq(nil)
      expect(serial_person.first[:household_key]).to eq(serial_other.first[:household_key])
    end
  end
end
