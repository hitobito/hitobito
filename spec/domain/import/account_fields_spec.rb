#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe Import::ContactAccountFields do
  subject { Import::ContactAccountFields.new(model) }

  context "PhoneNumber" do
    let(:model) { PhoneNumber }

    its(:keys) { should eq %w[phone_number_mobile phone_number_landline phone_number_work phone_number_other] }
    its(:values) {
      should eq ["Telefonnummer Mobil", "Telefonnummer Festnetz", "Telefonnummer Arbeit", "Telefonnummer Andere"]
    }

    its("fields.first") { should eq key: "phone_number_mobile", value: "Telefonnummer Mobil" }
  end

  context "SocialAccount" do
    let(:model) { SocialAccount }

    its(:keys) {
      should eq %w[social_account_facebook social_account_x_twitter social_account_website social_account_other]
    }
    its(:values) {
      should eq ["Social Media Adresse Facebook", "Social Media Adresse X (Twitter)",
        "Social Media Adresse Webseite", "Social Media Adresse Andere"]
    }
    its("fields.first") do
      should eq(key: "social_account_facebook", value: "Social Media Adresse Facebook")
    end
  end

  context "AdditionalEmail" do
    let(:model) { AdditionalEmail }

    its(:keys) {
      should eq %w[additional_email_private additional_email_work additional_email_invoices additional_email_other]
    }
    its(:values) {
      should eq ["Weitere E-Mail Privat", "Weitere E-Mail Arbeit", "Weitere E-Mail Rechnungsadresse",
        "Weitere E-Mail Andere"]
    }
    its("fields.first") do
      should eq(key: "additional_email_private", value: "Weitere E-Mail Privat")
    end
  end

  describe "#category_for" do
    let(:model) { PhoneNumber }

    it "resolves the category for a given key" do
      expect(subject.category_for("phone_number_landline"))
        .to eq contact_account_categories(:phone_number_person_landline)
    end

    it "returns nil for an unknown key" do
      expect(subject.category_for("phone_number_unknown")).to be_nil
    end
  end
end
