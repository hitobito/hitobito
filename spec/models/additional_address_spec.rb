# frozen_string_literal: true

#  Copyright (c) 2022-2026,  Eidgenössischer Jodlerverband. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe AdditionalAddress do
  let(:person) { people(:top_leader) }
  let(:labels) { %w[Foo Bar Buz] }

  before { allow(Settings.additional_address).to receive(:predefined_labels).and_return(labels) }

  describe "::validations" do
    let(:attrs) { Fabricate.build(:additional_address).attributes }

    subject(:address) { person.additional_addresses.build(attrs.merge(label: labels.first)) }

    it "builds valid address" do
      expect(address).to be_valid
      expect(address.save).to eq true
    end

    %w[street zip_code town country label].each do |attr|
      it "validates presence of #{attr}" do
        address.send(:"#{attr}=", nil)
        expect(address).not_to be_valid
        expect(address).to have(1).error_on(attr)
      end
    end

    it "mirrors the label error onto translated_label, since the form field is bound to it" do
      address.label = nil
      expect(address).not_to be_valid
      expect(address.errors[:translated_label]).to be_present
    end

    it "may use multiple address with multiple labels" do
      person.additional_addresses.build(Fabricate.build(:additional_address, label: "Foobar").attributes)
      expect(person).to be_valid
    end

    it "may not use same label twice" do
      person.additional_addresses.build(Fabricate.build(:additional_address, label: address.label).attributes)
      expect(person).not_to be_valid
      expect(person.errors.full_messages).to eq ["Die Bezeichnungen der weiteren Adressen müssen eindeutig sein."]
    end

    it "may not use invoices flag twice" do
      address.update!(invoices: true)
      person.additional_addresses.build(Fabricate.build(:additional_address, label: "Foobar",
        invoices: true).attributes)
      expect(person).not_to be_valid
      expect(person.errors.full_messages).to eq ["Es kann nur eine Adresse als Rechnungsadresse ausgewählt werden."]
    end

    it "allows false invoices flag multiple times" do
      Fabricate(:additional_address, contactable: person, invoices: false, label: "foo")
      address = Fabricate.build(:additional_address, contactable: person, invoices: false, label: "bar")
      expect(address).to be_valid
      expect(address.save).to eq true
    end

    it "requires a name" do
      address = Fabricate.build(:additional_address, contactable: person, uses_contactable_name: false)
      expect(address).not_to be_valid
      expect(address.errors.full_messages).to eq ["Bitte geben Sie einen Namen ein"]
      address.first_name = "Dummy"
      expect(address).to be_valid
    end

    it "requires organization_name if organization" do
      address = Fabricate.build(:additional_address, contactable: person, organization: true,
        uses_contactable_name: false)
      expect(address).not_to be_valid
      expect(address.errors.full_messages).to eq ["Firmenname muss ausgefüllt werden"]

      address.organization_name = "Firma INC"
      expect(address).to be_valid
    end
  end

  describe "using contactable name" do
    it "copies first_name and last_name from person" do
      address = Fabricate.build(:additional_address, contactable: person).tap(&:valid?)
      expect(address).to be_valid
      expect(address.first_name).to eq "Top"
      expect(address.last_name).to eq "Leader"
      expect(address.organization).to eq false
      expect(address.organization_name).to be_nil
      expect(address.name).to eq "Top Leader"
    end

    it "copies company infos from a company person" do
      contactable = Fabricate.build(:person, company: true, company_name: "Firma AG", first_name: nil,
        last_name: nil)

      address = Fabricate.build(:additional_address, contactable:).tap(&:valid?)
      expect(address).to be_valid
      expect(address.first_name).to be_nil
      expect(address.last_name).to be_nil
      expect(address.organization).to eq true
      expect(address.organization_name).to eq "Firma AG"
      expect(address.name).to eq "Firma AG"
    end

    it "treats group contactable as organization" do
      address = Fabricate.build(:additional_address, contactable: groups(:top_group)).tap(&:valid?)
      expect(address).to be_valid
      expect(address.first_name).to be_nil
      expect(address.last_name).to be_nil
      expect(address.organization).to eq true
      expect(address.organization_name).to eq "TopGroup"
      expect(address.name).to eq "TopGroup"
    end

    it "overrides existing names if true" do
      address = Fabricate.build(:additional_address, contactable: person, first_name: "foo", last_name: "bar",
        uses_contactable_name: true).tap(&:valid?)
      expect(address.first_name).to eq "Top"
      expect(address.last_name).to eq "Leader"
    end

    it "uses names as given if false" do
      address = Fabricate.build(:additional_address, contactable: person, first_name: "foo", last_name: "bar",
        uses_contactable_name: false).tap(&:valid?)
      expect(address.first_name).to eq "foo"
      expect(address.last_name).to eq "bar"
      expect(address.name).to eq "foo bar"
    end
  end

  describe "#name and #full_name" do
    subject(:address) {
      Fabricate.build(:additional_address, contactable: person, uses_contactable_name: false)
    }

    it "joins first_name and last_name for full_name" do
      address.first_name = "Jane"
      address.last_name = "Doe"
      expect(address.full_name).to eq "Jane Doe"
      expect(address.name).to eq "Jane Doe"
    end

    it "strips whitespace when only one part is given" do
      address.first_name = "Jane"
      address.last_name = nil
      expect(address.full_name).to eq "Jane"
    end

    it "is blank when neither first_name nor last_name is given" do
      address.first_name = nil
      address.last_name = nil
      expect(address.full_name).to be_nil
    end

    it "prefers organization_name over full_name when flagged as a organization" do
      address.first_name = "Jane"
      address.last_name = "Doe"
      address.organization = true
      address.organization_name = "Firma AG"
      expect(address.name).to eq "Firma AG"
      expect(address.full_name).to eq "Jane Doe"
    end

    it "falls back to full_name when flagged as a organization without a organization_name" do
      address.first_name = "Jane"
      address.last_name = "Doe"
      address.organization = true
      address.organization_name = nil
      expect(address.name).to eq "Jane Doe"
    end
  end

  describe "company aliases" do
    subject(:address) { Fabricate.build(:additional_address, contactable: person, uses_contactable_name: false) }

    it "reads and writes organization through the company alias" do
      address.company = true
      expect(address.organization).to eq true
      expect(address.organization?).to eq true

      address.company = false
      expect(address.organization).to eq false
    end

    it "reads and writes organization_name through the company_name alias" do
      address.company_name = "Firma AG"
      expect(address.organization_name).to eq "Firma AG"

      address.company_name = "Andere AG"
      expect(address.organization_name).to eq "Andere AG"
    end
  end

  context "#location" do
    subject(:address) { Fabricate.build(:additional_address, contactable: person, zip_code: 3005) }

    it "is nil if no location is found" do
      expect(address.location).to be_nil
    end

    it "returns location if found by zip code" do
      Location.create!(zip_code: "3005", name: "Bern", canton: "be")
      expect(address.location).to be_present
    end
  end

  describe "#to_s" do
    let(:attrs) {
      {
        address_care_of: "c/o Backoffice",
        street: "Langestrasse",
        housenumber: 37,
        zip_code: 8000,
        town: "Zürich",
        country: "CH"
      }
    }

    subject(:address) { described_class.new(attrs.merge(contactable: person)).tap(&:valid?) }

    it "renders address info on single line" do
      expect(address.to_s).to eq "Top Leader, c/o Backoffice, Langestrasse 37, 8000 Zürich"
    end

    it "renders postbox instead of town and zip_code" do
      address.postbox = "Postfach 1234"
      expect(address.to_s).to eq "Top Leader, c/o Backoffice, Langestrasse 37, Postfach 1234, 8000 Zürich"
    end

    it "includes country if not ignored" do
      address.country = "DE"
      address.zip_code = 12345
      address.town = "München"
      expect(address.to_s).to eq "Top Leader, c/o Backoffice, Langestrasse 37, 12345 München, Deutschland"
    end
  end
end
