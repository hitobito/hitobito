# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ContactAccountCategory do
  it "is valid with a name, key, contact_account_type and contactable_type" do
    entry = Fabricate.build(:contact_account_category)
    expect(entry).to be_valid
  end

  it "is invalid without a name" do
    entry = Fabricate.build(:contact_account_category, name: nil)
    expect(entry).not_to be_valid
  end

  it "is invalid with an unknown contact_account_type" do
    entry = Fabricate.build(:contact_account_category, contact_account_type: "Role")
    expect(entry).not_to be_valid
  end

  it "is invalid with an unknown contactable_type" do
    entry = Fabricate.build(:contact_account_category, contactable_type: "Event")
    expect(entry).not_to be_valid
  end

  it "allows the same key for different contactable_type" do
    attrs = {contact_account_type: "PhoneNumber", contactable_type: "Person", key: "custom"}
    Fabricate(:contact_account_category, attrs)
    other = Fabricate.build(:contact_account_category, attrs.merge(contactable_type: "Group"))
    expect(other).to be_valid
  end

  it "requires key to be unique per contact_account_type and contactable_type" do
    attrs = {contact_account_type: "PhoneNumber", contactable_type: "Person", key: "custom"}

    Fabricate(:contact_account_category, attrs)
    duplicate = Fabricate.build(:contact_account_category, attrs)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors.full_messages).to eq ["Schlüssel ist bereits vergeben"]
  end

  describe "used_for_invoices implies unique_per_contactable" do
    it "is invalid when used_for_invoices is set without unique_per_contactable" do
      entry = Fabricate.build(:contact_account_category, used_for_invoices: true,
        unique_per_contactable: false)

      expect(entry).not_to be_valid
      expect(entry.errors[:unique_per_contactable]).to be_present
      expect(entry.errors.full_messages)
        .to eq ["Nur einmal pro Person/Gruppe muss aktiviert sein, wenn 'Für Rechnungen verwenden' aktiviert ist"]
    end

    it "is valid when used_for_invoices and unique_per_contactable are both set" do
      entry = Fabricate.build(:contact_account_category, used_for_invoices: true,
        unique_per_contactable: true)

      expect(entry).to be_valid
    end

    it "is valid when used_for_invoices is not set, regardless of unique_per_contactable" do
      entry = Fabricate.build(:contact_account_category, used_for_invoices: false,
        unique_per_contactable: false)

      expect(entry).to be_valid
    end
  end

  describe ".for" do
    it "returns categories scoped to contact_account_type and contactable_type, ordered by position" do
      categories = ContactAccountCategory.for("PhoneNumber", "Person")

      expect(categories).to eq [
        contact_account_categories(:phone_number_person_mobile),
        contact_account_categories(:phone_number_person_landline),
        contact_account_categories(:phone_number_person_work),
        contact_account_categories(:phone_number_person_other)
      ]
    end
  end

  describe "#other?" do
    it "is true for the fallback category" do
      expect(contact_account_categories(:phone_number_person_other).other?).to eq true
    end

    it "is false for a named category" do
      expect(contact_account_categories(:phone_number_person_mobile).other?).to eq false
    end
  end

  it "#to_s returns the translated name" do
    entry = contact_account_categories(:phone_number_person_mobile)
    expect(entry.to_s).to eq "Mobil"
  end
end
