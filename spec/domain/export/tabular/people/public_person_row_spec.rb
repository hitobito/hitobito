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
      person.phone_numbers.create!(label: "Privat", number: "0791234567", public: true)
      expect(row.fetch(:phone_number_privat)).to eq "+41 79 123 45 67"
    end

    it "excludes non-public phone numbers" do
      person.phone_numbers.create!(label: "Mobil", number: "0791234000", public: false)
      expect(row.fetch(:phone_number_mobil)).to be_nil
    end
  end

  context "additional emails" do
    it "includes public additional emails" do
      person.additional_emails.create!(label: "Privat", email: "public@example.com", public: true)
      expect(row.fetch(:additional_email_privat)).to eq "public@example.com"
    end

    it "excludes non-public additional emails" do
      person.additional_emails.create!(label: "Arbeit", email: "secret@example.com", public: false)
      expect(row.fetch(:additional_email_arbeit)).to be_nil
    end
  end

  context "social accounts" do
    it "includes public social accounts" do
      person.social_accounts.create!(label: "Facebook", name: "public_fb", public: true)
      expect(row.fetch(:social_account_facebook)).to eq "public_fb"
    end

    it "excludes non-public social accounts" do
      person.social_accounts.create!(label: "Skype", name: "secret_skype", public: false)
      expect(row.fetch(:social_account_skype)).to be_nil
    end
  end

  context "free text labels" do
    it "includes public entries in free text column" do
      person.additional_emails.create!(label: "Ferien", email: "ferien@example.com", public: true)
      expect(row.fetch(:additional_email_custom_label)).to eq "Ferien:ferien@example.com"
    end

    it "excludes non-public entries from free text column" do
      person.additional_emails.create!(label: "Geheim", email: "geheim@example.com", public: false)
      expect(row.fetch(:additional_email_custom_label)).to be_nil
    end
  end
end
