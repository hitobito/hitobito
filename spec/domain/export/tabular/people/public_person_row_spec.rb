# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Export::Tabular::People::PublicPersonRow do
  let(:person) { people(:top_leader) }
  let(:row) { described_class.new(person) }

  context "phone numbers" do
    it "includes public phone numbers" do
      person.phone_numbers.create!(category: contact_account_categories(:phone_number_person_landline),
        number: "0791234567", public: true)
      expect(row.fetch(:phone_number_landline)).to eq "+41 79 123 45 67"
    end

    it "excludes non-public phone numbers" do
      person.phone_numbers.create!(category: contact_account_categories(:phone_number_person_mobile),
        number: "0791234000", public: false)
      expect(row.fetch(:phone_number_mobile)).to be_nil
    end
  end

  context "additional emails" do
    it "includes public additional emails" do
      person.additional_emails.create!(category: contact_account_categories(:additional_email_person_private),
        email: "public@example.com", public: true)
      expect(row.fetch(:additional_email_private)).to eq "public@example.com"
    end

    it "excludes non-public additional emails" do
      person.additional_emails.create!(category: contact_account_categories(:additional_email_person_work),
        email: "secret@example.com", public: false)
      expect(row.fetch(:additional_email_work)).to be_nil
    end
  end

  context "social accounts" do
    it "includes public social accounts" do
      person.social_accounts.create!(category: contact_account_categories(:social_account_person_facebook),
        name: "public_fb", public: true)
      expect(row.fetch(:social_account_facebook)).to eq "public_fb"
    end

    it "excludes non-public social accounts" do
      person.social_accounts.create!(category: contact_account_categories(:social_account_person_x_twitter),
        name: "secret_x", public: false)
      expect(row.fetch(:social_account_x_twitter)).to be_nil
    end
  end

  context "the other category" do
    it "includes public entries as label:value pairs" do
      person.additional_emails.create!(category: contact_account_categories(:additional_email_person_other),
        label: "Ferien", email: "ferien@example.com", public: true)
      expect(row.fetch(:additional_email_other)).to eq "Ferien:ferien@example.com"
    end

    it "excludes non-public entries" do
      person.additional_emails.create!(category: contact_account_categories(:additional_email_person_other),
        label: "Geheim", email: "geheim@example.com", public: false)
      expect(row.fetch(:additional_email_other)).to be_nil
    end
  end
end
