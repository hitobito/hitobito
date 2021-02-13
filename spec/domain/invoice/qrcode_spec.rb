# encoding: utf-8

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoice::Qrcode do
  let(:invoice) do
    Invoice.new(
      sequence_number: "1-1",
      payment_slip: :qr,
      total: 1500,
      iban: "CH93 0076 2011 6238 5295 7",
      payee: "Acme Corp\nHallesche Str. 37\n3007 Hinterdupfing\nCH",
      recipient_address: "Max Mustermann\nMusterweg 2\n8000 Alt Tylerland\nCH",
      reference: "RF561A1"
    )
  end

  describe :generate do
    it "generates image" do
      invoice.qrcode.generate do |file|
        image = ChunkyPNG::Image.from_file(file)
        expect(image.dimension.height).to eq 390
        expect(image.dimension.width).to eq 390
      end
    end
  end

  describe :payload do
    subject { invoice.qrcode.payload.split("\r\n") }

    it "has 31 distinct parts" do
      expect(subject).to have(31).items
    end

    it "has header part with type, version and coding" do
      expect(subject[0]).to eq "SPC"
      expect(subject[1]).to eq "0200"
      expect(subject[2]).to eq "1"
    end

    it "has iban stripped of whitespaces" do
      expect(subject[3]).to eq "CH9300762011623852957"
    end

    it "has recipient info of combined type" do
      expect(subject[4]).to eq "K"
      expect(subject[5]).to eq "Acme Corp"
      expect(subject[6]).to eq "Hallesche Str. 37"
      expect(subject[7]).to eq "3007 Hinterdupfing"
      expect(subject[8]).to be_blank
      expect(subject[9]).to be_blank
      expect(subject[10]).to eq "CH"
    end

    it "has blank final recipient info" do
      11.upto(17).each do |field|
        expect(subject[field]).to be_blank
      end
    end

    it "has payment information" do
      expect(subject[18]).to eq "1500.00"
      expect(subject[19]).to eq "CHF"
    end

    it "has final payment recipient of combined type" do
      expect(subject[20]).to eq "K"
      expect(subject[21]).to eq "Max Mustermann"
      expect(subject[22]).to eq "Musterweg 2"
      expect(subject[23]).to eq "8000 Alt Tylerland"
      expect(subject[24]).to be_blank
      expect(subject[25]).to be_blank
      expect(subject[26]).to eq "CH"
    end

    it "has SCOR reference" do
      expect(subject[27]).to eq "SCOR"
      expect(subject[28]).to eq "RF561A1"
    end

    it "has blank additional information " do
      expect(subject[29]).to be_blank
      expect(subject[30]).to eq "EPD"
      expect(subject[31]).to be_blank
    end

    it "has blank alternative payment method" do
      expect(subject[32]).to be_blank
    end
  end

  describe :additional_infos do
    subject { invoice.qrcode.additional_infos }

    it "reads payment_purpose" do
      invoice.payment_purpose = "Some\ndata"
      expect(subject[:purpose]).to eq "Some data"
      expect(subject[:trailer]).to eq "EPD"
      expect(subject[:infos]).to be_nil
    end

    it "truncates payment_purpose to 120 chars" do
      invoice.payment_purpose = "A" * 121
      expect(subject[:purpose].size).to eq 120
    end
  end

  describe :debitor do
    subject { invoice.qrcode.debitor }

    it "is extracted from recipient_address" do
      expect(subject[:address_type]).to eq "K"
      expect(subject[:full_name]).to eq "Max Mustermann"
      expect(subject[:address_line1]).to eq "Musterweg 2"
      expect(subject[:address_line2]).to eq "8000 Alt Tylerland"
      expect(subject[:zip_code]).to be_blank
      expect(subject[:town]).to be_blank
      expect(subject[:country]).to eq "CH"
    end

    it "handles empty values" do
      invoice.recipient_address = "Max Mustermann"
      expect(subject[:address_type]).to eq "K"
      expect(subject[:full_name]).to eq "Max Mustermann"
      %i[address_line1 address_line2 zip_code town].each do |key|
        expect(subject).to have_key(key)
        expect(subject[key]).to be_blank
      end
      expect(subject[:country]).to eq "CH"
    end

    it "handles zip without town" do
      invoice.recipient_address = "Max Mustermann\nMusterweg 2\n8000\nCH"
      expect(subject[:address_type]).to eq "K"
      expect(subject[:full_name]).to eq "Max Mustermann"
      expect(subject[:address_line1]).to eq "Musterweg 2"
      expect(subject[:address_line2]).to eq "8000"
      expect(subject[:zip_code]).to be_blank
      expect(subject[:town]).to be_blank
      expect(subject[:country]).to eq "CH"
    end

    it "handles blank lines" do
      invoice.recipient_address = "Max Mustermann\n \n \nCH"
      expect(subject[:address_type]).to eq "K"
      expect(subject[:full_name]).to eq "Max Mustermann"
      expect(subject[:address_line1]).to be_blank
      expect(subject[:address_line2]).to be_blank
      expect(subject[:zip_code]).to be_blank
      expect(subject[:town]).to be_blank
      expect(subject[:country]).to eq "CH"
    end
  end
end
