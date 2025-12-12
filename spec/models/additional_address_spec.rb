# frozen_string_literal: true

#  Copyright (c) 2022-2025,  Eidgenössischer Jodlerverband. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: additional_addresses
#
#  id                    :bigint           not null, primary key
#  address_care_of       :string
#  contactable_type      :string
#  country               :string           not null
#  housenumber           :string(20)
#  invoices              :boolean          default(FALSE), not null
#  label                 :string           not null
#  name                  :string           not null
#  postbox               :string
#  public                :boolean          default(FALSE), not null
#  street                :string           not null
#  town                  :string           not null
#  uses_contactable_name :boolean          default(TRUE), not null
#  zip_code              :string           not null
#  contactable_id        :bigint
#
# Indexes
#
#  idx_on_contactable_id_contactable_type_label_53043e4f10        (contactable_id,contactable_type,label) UNIQUE
#  index_additional_addresses_on_contactable                      (contactable_type,contactable_id)
#  index_additional_addresses_on_contactable_where_invoices_true  (contactable_id,contactable_type) UNIQUE WHERE (invoices = true)
#
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
  end

  describe "#uses_contactable_name" do
    it "populates blank name if true" do
      address = Fabricate.build(:additional_address, contactable: person, uses_contactable_name: true).tap(&:valid?)
      expect(address.name).to eq "Top Leader"
    end

    it "overrides existing name if true" do
      address = Fabricate.build(:additional_address, contactable: person, name: "foo",
        uses_contactable_name: true).tap(&:valid?)
      expect(address.name).to eq "Top Leader"
    end

    it "uses name as given if false" do
      address = Fabricate.build(:additional_address, contactable: person, name: "foo",
        uses_contactable_name: false).tap(&:valid?)
      expect(address.name).to eq "foo"
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
