# frozen_string_literal: true

#  Copyright (c) 2022-2025,  Eidgenössischer Jodlerverband. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: additional_addresses
#
#  id               :bigint           not null, primary key
#  address_care_of  :string
#  contactable_type :string
#  country          :string           not null
#  housenumber      :string(20)
#  label            :string           not null
#  postbox          :string
#  street           :string           not null
#  town             :string           not null
#  zip_code         :string           not null
#  contactable_id   :bigint
#
# Indexes
#
#  idx_on_contactable_id_contactable_type_label_53043e4f10  (contactable_id,contactable_type,label) UNIQUE
#  index_additional_addresses_on_contactable                (contactable_type,contactable_id)
#

require "spec_helper"

describe AdditionalAddress do
  let(:person) { people(:top_leader) }
  let(:labels) { %w[Foo Bar Buz] }

  before { allow(Settings.additional_address).to receive(:predefined_labels).and_return(labels) }

  describe "::validations" do
    subject(:address) { Fabricate.build(:additional_address, contactable: person) }

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

    it "does not allow reusing label twice" do
      Fabricate(:additional_address, contactable: person)
      expect(address).not_to be_valid
      expect(address).to have(1).error_on(:label)
      expect(address.errors.full_messages).to eq ["Label ist bereits vergeben"]
    end

    it "does support two address with distinct labels" do
      Fabricate(:additional_address, contactable: person)
      address.label = labels.second
      expect(address).to be_valid
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

    subject(:address) { described_class.new(attrs) }

    it "renders address info on single line" do
      expect(address.to_s).to eq "c/o Backoffice, Langestrasse 37, 8000 - Zürich"
    end

    it "renders postbox instead of town and zip_code" do
      address.postbox = "Postfach 1234"
      expect(address.to_s).to eq "c/o Backoffice, Langestrasse 37, Postfach 1234"
    end

    it "includes country if not ignored" do
      address.country = "DE"
      address.zip_code = 12345
      address.town = "München"
      expect(address.to_s).to eq "c/o Backoffice, Langestrasse 37, 12345 - München, Deutschland"
    end
  end
end
