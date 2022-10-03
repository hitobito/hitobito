# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.


require 'spec_helper'

describe MailingLists::BulkMail::BounceMessageForwardJob do
  include MailingLists::ImapMailsSpecHelper

  let(:mailing_list) { mailing_lists(:leaders) }
  let(:raw_bounce_mail) { Mail.read_from_string(File.read(Rails.root.join('spec', 'fixtures', 'email', 'list_bounce.eml'))) }

  let(:bulk_mail_bounce) do
    Message::BulkMailBounce.create!(
      state: :pending,
      bounce_parent: messages(:mail),
      raw_source: raw_bounce_mail,
      subject: 'Undelivered Mail Returned to Sender')
  end

  let!(:mail_log) do
    MailLog.create!(
      mail_from: 'MAILER-DAEMON@example.com',
      message: bulk_mail_bounce,
      mail_hash: 'abcd42')
  end

  subject { described_class.new(bulk_mail_bounce) }

  it 'forwards bounce message' do
    Settings.email.retriever.config = Config::Options.new(address: 'localhost')
    Settings.email.list_domain = 'hitobito.example.com'

    expect(Rails.logger).to receive(:info)
      .with("Bounce Message Forwarding: Forwarding bounce message for list leaders@#{Settings.email.list_domain} to sender@example.com")
    allow(Rails.logger).to receive(:info)

    subject.perform

    expect(last_email.to).to eq(["sender@example.com"])
    expect(last_email.from).to eq(["noreply@hitobito.example.com"])
    expect(last_email.subject).to eq("Undelivered Mail Returned to Sender")

    expect(mail_log.reload.status).to eq('completed')
    expect(bulk_mail_bounce.reload.raw_source).to be_nil
    expect(bulk_mail_bounce.state).to eq('finished')
  end
end
