#  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::QrcodeAddress do
  describe "initialize" do
    it "raises for invalid address type" do
      expect do
        described_class.new(["C", nil, nil, nil, nil, nil, nil])
      end.to raise_error "Uknown address type 'C'"
    end

    it "raises for invalid amount of values" do
      expect do
        described_class.new(["S", nil, nil, nil, nil, nil])
      end.to raise_error "Expected exactly 7 values, got 6"
    end
  end

  describe "to_h" do
    it "returns values as hash where keys have the correct order" do
      values = ["S", "Max Mustermann", "Musterstrasse", "42b", "1234", "Musterhausen", "CH"]

      hash = described_class.new(values).to_h

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
      values = ["S", "Max Mustermann", "Musterstrasse", "42b", "1234", "Musterhausen", nil]

      address = described_class.new(values).readable_address

      expect(address).to eq <<~TEXT.chomp
        Max Mustermann
        Musterstrasse 42b
        1234 Musterhausen
      TEXT
    end

    it "handles unstructured address" do
      values = ["K", "Max Mustermann", "Musterstrasse 42b", "1234 Musterhausen", nil, nil, nil]

      address = described_class.new(values).readable_address

      expect(address).to eq <<~TEXT.chomp
        Max Mustermann
        Musterstrasse 42b
        1234 Musterhausen
      TEXT
    end

    it "handles missing value" do
      values = ["S", "Max Mustermann", "Musterstrasse", "42b", nil, "Musterhausen", nil]

      address = described_class.new(values).readable_address

      expect(address).to eq <<~TEXT.chomp
        Max Mustermann
        Musterstrasse 42b
        Musterhausen
      TEXT
    end

    it "handles missing line" do
      values = ["S", "Max Mustermann", nil, nil, "1234", "Musterhausen", nil]

      address = described_class.new(values).readable_address

      expect(address).to eq <<~TEXT.chomp
        Max Mustermann
        1234 Musterhausen
      TEXT
    end
  end
end
