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
    expect(mail['Return-Path'].value.first).to eq('sender@example.com')
    expect(mail['Reply-To'].value.first).to eq('sender@example.com')
  end

  it 'sets recipient email addresses to smtp envelope to' do
    recipient_emails = ['one@example.com', 'two@example.com']
    factory.to(recipient_emails)

    recipients = mail.smtp_envelope_to
    expect(recipients.count).to eq(2)
    expect(recipients).to include('one@example.com')
    expect(recipients).to include('two@example.com')
  end

  private

  def mail
    factory.instance_variable_get(:@mail)
  end

end
