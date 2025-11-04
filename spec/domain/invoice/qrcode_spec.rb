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
      recipient_address: "Max Mustermann\nMusterweg 2\n8000 Alt Tylerland",
      qr_code_creditor_values: ["S", "Acme Corp", "Hallesche Str.", "37", "3007", "Hinterdupfing", "CH"],
      qr_code_debitor_values: ["S", "Max Mustermann", "Musterweg", "2", "8000", "Alt Tylerland", "CH"],
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
      expect(subject[4]).to eq "S"
      expect(subject[5]).to eq "Acme Corp"
      expect(subject[6]).to eq "Hallesche Str."
      expect(subject[7]).to eq "37"
      expect(subject[8]).to eq "3007"
      expect(subject[9]).to eq "Hinterdupfing"
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

    it "has blank amount if invoice has no total" do
      invoice.total = 0
      expect(subject[18]).to be_blank
      expect(subject[19]).to eq "CHF"
    end

    it "has final payment recipient of combined type" do
      expect(subject[20]).to eq "S"
      expect(subject[21]).to eq "Max Mustermann"
      expect(subject[22]).to eq "Musterweg"
      expect(subject[23]).to eq "2"
      expect(subject[24]).to eq "8000"
      expect(subject[25]).to eq "Alt Tylerland"
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

    it "has total if total is not hidden" do
      invoice.hide_total = false

      expect(subject[18]).to eq("1500.00")
    end

    it "has no total if total is hidden" do
      invoice.hide_total = true

      expect(subject[18]).to be_blank
    end

    context "with nil iban on invoice" do
      before { invoice.update(iban: nil) }

      it "works" do
        expect(subject).to have(31).items
      end
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

    it "is qr code address" do
      expect(subject.readable_address).to eq <<~TEXT.chomp
        Max Mustermann
        Musterweg 2
        8000 Alt Tylerland
      TEXT
    end
  end

  describe :payment_reference do
    it "type NONE if reference blank" do
      invoice.reference = nil
      expect(invoice.qrcode.payment_reference[:type]).to eq("NON")
      expect(invoice.qrcode.payment_reference[:reference]).to eq(nil)
    end

    it "SCOR if reference starts with RF" do
      invoice.reference = "RFctt"
      expect(invoice.qrcode.payment_reference[:type]).to eq("SCOR")
      expect(invoice.qrcode.payment_reference[:reference]).to eq("RFctt")
    end

    it "QRR if reference does not start with RF but is present" do
      invoice.reference = "GTRBS"
      expect(invoice.qrcode.payment_reference[:type]).to eq("QRR")
      expect(invoice.qrcode.payment_reference[:reference]).to eq("GTRBS")
    end
  end
end
