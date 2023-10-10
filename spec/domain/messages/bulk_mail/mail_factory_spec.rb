# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::BulkMail::MailFactory do

  let(:bulk_mail_message) { messages(:mail) }
  let(:factory) { described_class.new(bulk_mail_message) }

  it 'sets original sender to reply headers' do
    expect(mail['Reply-To'].value).to eq('sender@example.com')
  end

  it 'sets recipient email addresses to smtp envelope to' do
    recipient_emails = ['one@example.com', 'two@example.com']
    factory.to(recipient_emails)

    recipients = mail.smtp_envelope_to
    expect(recipients.count).to eq(2)
    expect(recipients).to include('one@example.com')
    expect(recipients).to include('two@example.com')
  end

  it 'sets smtp envelope from and headers' do
    expect(mail['X-Hitobito-Message-UID'].value).to eq('a15816bbd204ba20')
    expect(mail['from'].value).to eq("Mike Sender via leaders@#{Settings.email.list_domain} <leaders@#{Settings.email.list_domain}>")
    expect(mail.smtp_envelope_from).to eq("leaders@#{Settings.email.list_domain}")
  end

  it 'sets from to sender e-mail if no sender name given' do
    raw_mail = bulk_mail_message.raw_source
    raw_mail.gsub!('From: Mike Sender <sender@example.com>', 'From: <sender@example.com>')
    bulk_mail_message.raw_source = raw_mail

    expect(mail['from'].value).to eq("sender@example.com via leaders@#{Settings.email.list_domain} <leaders@#{Settings.email.list_domain}>")
  end

  private

  def mail
    factory.instance_variable_get(:@mail)
  end

end
