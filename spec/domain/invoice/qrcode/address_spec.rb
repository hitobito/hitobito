#  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::Qrcode::Address do
  describe "initialize" do
    it "raises for invalid address type" do
      expect do
        described_class.new(
          address_type: "C",
          full_name: nil,
          street: nil,
          housenumber: nil,
          zip_code: nil,
          town: nil,
          country: nil
        )
      end.to raise_error "Unknown address type 'C'"
    end

    it "normalizes input" do
      address = described_class.new(
        address_type: "S",
        full_name: "Max Mustermann ",
        street: " Musterstrasse",
        housenumber: nil,
        zip_code: nil,
        town: nil,
        country: nil
      )

      expect(address.full_name).to eq "Max Mustermann"
      expect(address.street).to eq "Musterstrasse"
    end
  end

  describe "to_h" do
    it "returns values as hash where keys have the correct order" do
      address = described_class.new(
        address_type: "S",
        full_name: "Max Mustermann",
        street: "Musterstrasse",
        housenumber: "42b",
        zip_code: "1234",
        town: "Musterhausen",
        country: "CH"
      )

      hash = address.to_h

      expect(hash).to eq(
        {
          address_type: "S",
          full_name: "Max Mustermann",
          street: "Musterstrasse",
          housenumber: "42b",
          zip_code: "1234",
          town: "Musterhausen",
          country: "CH"
        }
      )
      expect(hash.keys).to eq [:address_type, :full_name, :street, :housenumber, :zip_code, :town, :country]
    end
  end

  describe "readable_address" do
    it "handles structured address" do
      address = described_class.new(
        address_type: "S",
        full_name: "Max Mustermann",
        street: "Musterstrasse",
        housenumber: "42b",
        zip_code: "1234",
        town: "Musterhausen",
        country: nil
      )

      expect(address.readable_address).to eq <<~TEXT.chomp
        Max Mustermann
        Musterstrasse 42b
        1234 Musterhausen
      TEXT
    end

    it "handles unstructured address" do
      address = described_class.new(
        address_type: "K",
        full_name: "Max Mustermann",
        street: "Musterstrasse 42b",
        housenumber: "1234 Musterhausen",
        zip_code: nil,
        town: nil,
        country: nil
      )

      expect(address.readable_address).to eq <<~TEXT.chomp
        Max Mustermann
        Musterstrasse 42b
        1234 Musterhausen
      TEXT
    end

    it "handles missing value" do
      address = described_class.new(
        address_type: "S",
        full_name: "Max Mustermann",
        street: "Musterstrasse",
        housenumber: "42b",
        zip_code: nil,
        town: "Musterhausen",
        country: nil
      )

      expect(address.readable_address).to eq <<~TEXT.chomp
        Max Mustermann
        Musterstrasse 42b
        Musterhausen
      TEXT
    end

    it "handles missing line" do
      address = described_class.new(
        address_type: "S",
        full_name: "Max Mustermann",
        street: nil,
        housenumber: nil,
        zip_code: "1234",
        town: "Musterhausen",
        country: nil
      )

      expect(address.readable_address).to eq <<~TEXT.chomp
        Max Mustermann
        1234 Musterhausen
      TEXT
    end
  end
end
