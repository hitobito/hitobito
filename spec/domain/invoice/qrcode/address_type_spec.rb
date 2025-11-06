require "rails_helper"

RSpec.describe Invoice::Qrcode::AddressType do
  let(:address_attributes) do
    {
      address_type: "S",
      full_name: "Max Mustermann",
      street: "Musterstrasse",
      housenumber: "42b",
      zip_code: "1234",
      town: "Musterhausen",
      country: "CH"
    }
  end
  let(:address) { Invoice::Qrcode::Address.new(**address_attributes) }

  describe "#serialize" do
    context "when value is present" do
      it "converts the address to JSON hash" do
        result = described_class.new.serialize(address)

        expect(result).to be_a(String)
        expect(JSON.parse(result)).to eq(address_attributes.stringify_keys)
      end
    end

    context "when value is nil" do
      it "returns nil" do
        expect(described_class.new.serialize(nil)).to be_nil
      end
    end
  end

  describe "#cast" do
    context "when value is a JSON string" do
      let(:json_string) { address_attributes.to_json }

      it "parses JSON and creates an Address instance" do
        address = described_class.new.cast(json_string)

        expect(address).to be_a(Invoice::Qrcode::Address)
        expect(address.address_type).to eq("S")
        expect(address.full_name).to eq("Max Mustermann")
        expect(address.street).to eq("Musterstrasse")
        expect(address.housenumber).to eq("42b")
        expect(address.zip_code).to eq("1234")
        expect(address.town).to eq("Musterhausen")
        expect(address.country).to eq("CH")
      end
    end

    context "when value is already an Address instance" do
      it "returns the value unchanged" do
        result = described_class.new.cast(address)

        expect(result).to eq(address)
      end
    end

    context "when value is nil" do
      it "returns nil" do
        expect(described_class.new.cast(nil)).to be_nil
      end
    end
  end
end
