# frozen_string_literal: true

# == Schema Information
#
# Table name: invoice_configs
#
#  id                               :integer          not null, primary key
#  account_number                   :string
#  address                          :text
#  beneficiary                      :text
#  currency                         :string           default("CHF"), not null
#  donation_calculation_year_amount :integer
#  donation_increase_percentage     :integer
#  due_days                         :integer          default(30), not null
#  email                            :string
#  iban                             :string
#  logo_position                    :string           default("disabled"), not null
#  participant_number               :string
#  payee                            :text
#  payment_information              :text
#  payment_slip                     :string           default("qr"), not null
#  sender_name                      :string
#  sequence_number                  :integer          default(1), not null
#  vat_number                       :string
#  group_id                         :integer          not null
#
# Indexes
#
#  index_invoice_configs_on_group_id  (group_id)
#

require "spec_helper"

describe InvoiceConfig do
  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }
  let(:invoice_config) { group.invoice_config }

  describe "payment_slip dependent validations" do
    subject { Fabricate(Group::BottomLayer.sti_name, id: 1).reload.invoice_config }

    it "qr" do
      subject.payment_slip = "qr"
      expect(subject).not_to be_valid
      expect(subject.errors.attribute_names).to eq [:payee, :iban]
    end

    it "no_ps" do
      subject.payment_slip = "no_ps"
      expect(subject).not_to be_valid
      expect(subject.errors.attribute_names).to eq [:payee]
    end
  end

  it "validates correct payee format for qr payment_slip" do
    invoice_config.update(payment_slip: "qr", payee: "anything goes NOT")
    expect(invoice_config).not_to be_valid
    expect(invoice_config.errors.full_messages).to eq ["Einzahlung für muss genau 3 Zeilen enthalten"]

    invoice_config.update(
      payment_slip: "qr",
      payee: <<~PAYEE
        Mando Muster
        Einestrasse 1
        4242 Kaff
        One more line
      PAYEE
    )
    expect(invoice_config).not_to be_valid
    expect(invoice_config.errors.full_messages).to eq ["Einzahlung für muss genau 3 Zeilen enthalten"]

    invoice_config.update(
      payment_slip: "qr",
      payee: <<~PAYEE
        Mando Muster
        Einestrasse 1
        4242 Kaff
      PAYEE
    )
    expect(invoice_config).to be_valid
  end

  it "validates correct iban format" do
    invoice_config.update(iban: "wrong format")

    expect(invoice_config).not_to be_valid
    expect(invoice_config.errors.full_messages).to include("IBAN ist nicht gültig")
  end

  it "validates presence of payee" do
    invoice_config.update(payee: "")

    expect(invoice_config).not_to be_valid
  end

  it "validates account_number check digit if post payment" do
    # incorrect check digit
    invoice_config.update(account_number: "12-123-1")

    expect(invoice_config).not_to be_valid
    expect(invoice_config.errors.full_messages).to include(/Inkorrekte Prüfziffer/)

    # correct check digit
    invoice_config.update(account_number: "12-123-9")

    expect(invoice_config).to be_valid
  end

  it "validates reference_prefix to be a number" do
    invoice_config.update(reference_prefix: "some string")

    expect(invoice_config).not_to be_valid
  end

  it "validates reference_prefix to not be longer than 7 characters" do
    invoice_config.update(reference_prefix: 12345678)

    expect(invoice_config).not_to be_valid
  end

  describe "e-mail validation" do
    before { allow(Truemail).to receive(:valid?).and_call_original }

    it "does not allow invalid e-mail address" do
      invoice_config.email = "blabliblu-ke-email"

      expect(invoice_config).not_to be_valid
      expect(invoice_config.errors.messages[:email].first).to eq("ist nicht gültig")
    end

    it "allows blank e-mail address" do
      invoice_config.email = "   "

      expect(invoice_config).to be_valid
      expect(invoice_config.email).to be_nil
    end

    it "does not allow e-mail address with non-existing domain" do
      invoice_config.email = "invoices42@gitsäuäniä.it"

      expect(invoice_config).not_to be_valid
      expect(invoice_config.errors.messages[:email].first).to eq("ist nicht gültig")
    end

    it "does not allow e-mail address with domain without mx record" do
      invoice_config.email = "invoices@bluewin.com"

      expect(invoice_config).not_to be_valid
      expect(invoice_config.errors.messages[:email].first).to eq("ist nicht gültig")
    end

    it "does allow valid e-mail address" do
      invoice_config.email = "invoice42@puzzle.ch"

      expect(invoice_config).to be_valid
    end
  end

  describe "sender_name validation" do
    it "allows special characters" do
      invoice_config.sender_name = "Étienne Müller / Sami +*"

      expect(invoice_config).to be_valid
    end

    it "doesnt allow emails" do
      invoice_config.sender_name = "hitobito@bern.ch"

      expect(invoice_config).not_to be_valid
      expect(invoice_config.errors.messages[:sender_name].first).to eq("ist nicht gültig")
    end
  end

  describe "normalization" do
    it "downcases email" do
      invoice_config.email = "TesTer@gMaiL.com"
      expect(invoice_config.email).to eq "tester@gmail.com"
    end
  end

  context "#logo_enabled?" do
    context "with logo attached" do
      before { invoice_config.logo.attach(fixture_file_upload("images/logo.png")) }

      it "returns true when logo_position is left" do
        invoice_config.logo_position = "left"
        expect(invoice_config.send(:logo_enabled?)).to be(true)
      end

      it "returns true when logo_position is right" do
        invoice_config.logo_position = "right"
        expect(invoice_config.send(:logo_enabled?)).to be(true)
      end

      it "returns false when logo_position is disabled" do
        invoice_config.logo_position = "disabled"
        expect(invoice_config.send(:logo_enabled?)).to be(false)
      end

      it "returns false when logo_position is nil" do
        invoice_config.logo_position = nil
        expect(invoice_config.send(:logo_enabled?)).to be(false)
      end
    end
  end
end
