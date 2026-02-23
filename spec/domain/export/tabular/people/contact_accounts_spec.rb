#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::ContactAccounts do
  subject { Export::Tabular::People::ContactAccounts }

  context "phone_numbers" do
    it "creates standard key and human translations" do
      expect(subject.key(PhoneNumber, "foo")).to eq :phone_number_foo
      expect(subject.human(PhoneNumber, "foo")).to eq "Telefonnummer foo"
    end

    it "uses first predefined_label if label is nil" do
      expect(subject.key(PhoneNumber, nil)).to eq :phone_number_privat
      expect(subject.human(PhoneNumber, nil)).to eq "Telefonnummer Privat"
    end
  end

  context "social_accounts" do
    it "creates standard key and human translations" do
      expect(subject.key(SocialAccount, "foo")).to eq :social_account_foo
      expect(subject.human(SocialAccount, "foo")).to eq "Social Media Adresse foo"
    end
  end

  context "free_text" do
    it "creates free text key" do
      expect(subject.free_text_key(PhoneNumber)).to eq :phone_number_free_text
      expect(subject.free_text_key(AdditionalEmail)).to eq :additional_email_free_text
    end

    it "creates free text human label with plural model name" do
      expect(subject.free_text_human(PhoneNumber)).to eq "Telefonnummern Freitext"
      expect(subject.free_text_human(AdditionalEmail)).to eq "Weitere E-Mails Freitext"
    end
  end

  context "predefined_labels" do
    it "returns predefined labels from settings" do
      expect(subject.predefined_labels(PhoneNumber)).to include("Privat", "Mobil", "Arbeit")
    end
  end

  context "free_text_label_enabled?" do
    it "returns false for phone_number" do
      expect(subject.free_text_label_enabled?(PhoneNumber)).to be false
    end

    it "returns true for additional_email" do
      expect(subject.free_text_label_enabled?(AdditionalEmail)).to be true
    end
  end
end
