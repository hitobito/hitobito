# frozen_string_literal: true

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
require "spec_helper"

describe InvoiceMailer do
  let(:invoice) { invoices(:invoice) }
  let(:sender) { people(:bottom_member) }
  let(:mail) { InvoiceMailer.notification(invoice, sender) }
  let(:html) { mail.body.parts.find { |p| p.content_type =~ /html/ }.to_s }
  let(:pdf) { mail.body.parts.find { |p| p.content_type =~ /pdf/ } }

  subject { mail }

  its(:to) { should == [invoice.recipient.email] }
  its(:reply_to) { should == [sender.email] }
  its(:subject) { should =~ /Rechnung \d+-\d+ von Bottom One/ }

  it "renders body if invoice.recipient is missing" do
    invoice.update(recipient: nil, recipient_email: "test@example.com")
    invoice.update_columns(
      recipient_company_name: nil,
      recipient_name: nil,
      recipient_address_care_of: nil,
      recipient_street: nil,
      recipient_housenumber: nil,
      recipient_postbox: nil,
      recipient_zip_code: nil,
      recipient_town: nil
    )
    expect(html).to match("test@example.com")
  end

  it "uses sender email in mail headers" do
    expect(mail.from).to eq ["noreply@localhost"]
    expect(mail.sender).to match(/^noreply-bounces\+bottom_member=example\.com@/)
    expect(mail.reply_to).to eq %w[bottom_member@example.com]
  end

  it "uses invoice_config.email in mail headers" do
    invoice.invoice_config.update(email: "invoices@example.com")
    expect(mail.from).to eq %w[noreply@localhost]
    expect(mail.sender).to match(/^noreply-bounces\+invoices=example\.com@/)
    expect(mail.reply_to).to eq %w[invoices@example.com]
  end

  it "uses invoice_config.sender_name in mail headers" do
    invoice.invoice_config.update(sender_name: "Étienne Müller / Sami +*")
    expect(mail.header["From"].to_s).to eq("\"Étienne Müller / Sami +*\" <noreply@localhost>")
    expect(mail.sender).to eq("noreply-bounces+bottom_member=example.com@localhost")
    expect(mail.reply_to).to eq %w[bottom_member@example.com]
  end

  context "with custom content in invoice_config" do
    let!(:invoice_config_custom_content) do
      custom_contents(:content_invoice_notification).update!(placeholders_required: nil)

      Fabricate(:custom_content, context: invoice.invoice_config,
        subject: "Invoice Config",
        body: "I am not a global custom content",
        key: custom_contents(:content_invoice_notification).key)
    end

    it "uses custom content defined in invoice config" do
      expect(mail.subject).to eq("Invoice Config")
    end

    it "uses global custom content when custom content is in different invoice config" do
      invoice_config_custom_content.update!(context: invoice_configs(:bottom_layer_two))
      expect(mail.subject).to eq("Rechnung 376803389-2 von Bottom One")
    end
  end

  describe :html_body do
    it "includes group address" do
      expect(html).to match(/Absender: Bottom One, Greatstreet 345, 3456 Greattown/)
    end

    it "lists pins items" do
      expect(html).to match(/pins.*0.50 CHF/)
    end

    it "has calculated total" do
      expect(html).to match(/Rechnungsbetrag.*5\.35 CHF/)
    end
  end

  describe :pdf_body do
    let(:invoice) { invoices(:sent) }

    it "includes filename" do
      expect(pdf.content_type).to match(/filename=#{invoice.filename}/)
    end

    it "renders invoice with payment reminders" do
      Fabricate(
        :payment_reminder,
        invoice:,
        due_at: invoice.due_at + 1.day,
        title: "Zahlungserinnerung",
        text: "Im hektischen Alltag .."
      )
      texts = PDF::Inspector::Text.analyze(pdf.body.raw_source).show_text
      expect(texts).to include "Zahlungserinnerung - Sent Person Invoice"
      expect(texts).to include "Im hektischen Alltag .."
    end
  end

  context "without managers" do
    its(:cc) { should be_empty }
  end

  context "with manager" do
    let(:manager) { people(:bottom_member) }
    let(:recipient) { invoice.recipient }

    before do
      recipient.managers << manager
      recipient.save!
    end

    its(:cc) { should == [manager.email] }

    context "with invoice email" do
      before do
        manager.additional_emails.create!(email: "invoices@example.com", label: "Privat", invoices: true)
      end

      its(:cc) { should == ["invoices@example.com"] }
    end
  end
end
