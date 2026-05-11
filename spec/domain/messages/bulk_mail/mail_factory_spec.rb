# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Messages::BulkMail::MailFactory do
  let(:bulk_mail_message) { messages(:mail) }
  let(:factory) { described_class.new(bulk_mail_message) }
  let(:ml_address) { "#{bulk_mail_message.mailing_list.mail_name}@#{Settings.email.list_domain}" }

  it "sets original sender to reply headers" do
    expect(mail["Reply-To"].value).to eq("sender@example.com")
  end

  it "sets recipient email addresses to smtp envelope to" do
    recipient_emails = ["one@example.com", "two@example.com"]
    factory.to(recipient_emails)

    recipients = mail.smtp_envelope_to
    expect(recipients.count).to eq(2)
    expect(recipients).to include("one@example.com")
    expect(recipients).to include("two@example.com")
  end

  it "add a custom header to identify the message being relayed" do
    expect(mail["X-Hitobito-Message-UID"].value).to eq("a15816bbd204ba20")
  end

  it "sets smtp envelope from and headers" do
    expect(mail["from"].value).to eq(%("Mike Sender via #{ml_address}" <#{ml_address}>))
    expect(mail.smtp_envelope_from).to eq(ml_address)
  end

  it "sets from to sender e-mail if no sender name given" do
    raw_mail = bulk_mail_message.raw_source
    raw_mail.gsub!("From: Mike Sender <sender@example.com>", "From: <sender@example.com>")
    bulk_mail_message.raw_source = raw_mail

    expect(mail["from"].value).to eq(%("sender@example.com via #{ml_address}" <#{ml_address}>))
  end

  it "wraps the 'from-name' in quotes to avoid accidental splitting" do
    raw_mail = bulk_mail_message.raw_source
    raw_mail.gsub!("From: Mike Sender <sender@example.com>", 'From: "Mike Sender, Chief" <sender@example.com>')
    bulk_mail_message.raw_source = raw_mail

    expect(mail["from"].value).to eq(%("Mike Sender, Chief via #{ml_address}" <#{ml_address}>))
    expect(mail["from"].display_names.first).to eq %(Mike Sender, Chief via #{ml_address})
  end

  it "respects and quotes the double-quotes in the 'from-name'" do
    raw_mail = bulk_mail_message.raw_source
    raw_mail.gsub!("From: Mike Sender <sender@example.com>", 'From: "Mike \"Raw Phone\" Sender" <sender@example.com>')
    bulk_mail_message.raw_source = raw_mail

    expect(mail["from"].value).to eq(%("Mike \\"Raw Phone\\" Sender via #{ml_address}" <#{ml_address}>))
    expect(mail["from"].display_names.first).to eq %(Mike "Raw Phone" Sender via #{ml_address})
  end

  it "sets To header to 'Undisclosed recipients:;' when empty" do
    raw_mail = bulk_mail_message.raw_source.gsub(/^To:.*\n/, "")
    bulk_mail_message.raw_source = raw_mail

    expect(mail.encoded).to include("To: Undisclosed recipients:;")
  end

  it "does not modify To header when already present" do
    expect(mail.encoded).to include("To: leaders@localhost")
  end

  it "sets To header when mail was sent via BCC" do
    raw_mail = bulk_mail_message.raw_source.gsub(/^To:.*\n/, "Bcc: leaders@localhost\n")
    bulk_mail_message.raw_source = raw_mail

    expect(mail.encoded).to include("To: Undisclosed recipients:;")
  end

  private

  def mail
    factory.instance_variable_get(:@mail)
  end
end
