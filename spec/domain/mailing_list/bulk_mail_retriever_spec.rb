# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingList::BulkMailRetriever do
  include MailingLists::ImapMailsHelper

  let(:connector) { described_class.new }
  let(:imap_connector) { double(:imap_connector) }
  let(:mailing_list) { mailing_lists(:leaders) }

  it 'receives mail and enqueues dispatch' do
    # mock fetched mails
    imap_mails = [
      new_imap_mail
    ]

    # mock imap_connector calls
    expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mails)
    expect(imap_connector).to receive(:delete).with(:mail_id).once

    # execute 'job'
    expect do
      connector.perform
    end
    .to change { mailing_list.messages.count }.by(1)
    .and exist('rails/store/mailing_list/bulk_mail' + imap_mails.first.uid.to_s + '.yaml')
    .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(1)

    message = mailing_list.messages.first
    expect(message.subject).to eq('Supermail report')
    expect(message.sender).to eq('superman')
  end

  it 'terminates if imap server not reachable' do
    imap_mails = []

    # expect error to be thrown
    expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mails)
    expect(imap_connector).to receive(:delete).with(:mail_id).and_return(Net::IMAP::NoResponseError)

    expect do
      connector.perform
    end.to raise { Net::IMAP::NoResponseError }
  end

  it 'drops mail if cannot be assigned to mailing list' do
    imap_mails = []
    expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mails)
    expect(imap_connector).to receive(:delete).with(:mail_id)

    expect do
      connector.perform
    end
      .to change { mailing_list.messages.count }.by(1)
                                                .and exist('rails/store/' + :mail_id.to_s)
                                                       .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(1)

    message = mailing_list.messages.first
    expect(message.subject).to eq('Supermail report')
    expect(message.sender).to eq('superman')
  end

  it 'sends mail to sender if not allowed to send form mailing list' do
    imap_mails = []
    expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mails)
    expect(imap_connector).to receive(:delete).with(:mail_id)

    connector.perform
    expect(connector).to receive(:unallowed_sender)
  end

  it 'skips if no new mail in mailbox available' do
    imap_mails = []
    expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mails)
    expect(imap_connector).to receive(:delete).with(:mail_id)

    expect do
      connector.perform
    end
    .to change { mailing_list.messages.count }.by(1)
    .and exist('rails/store/' + :mail_id.to_s)
    .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(1)

    message = mailing_list.messages.first
    expect(message.subject).to eq('Supermail report')
    expect(message.sender).to eq('superman')
  end

  it 'raises exception if unknown error' do
    imap_mails = []
    expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mails)
    expect(imap_connector).to receive(:delete).with(:mail_id)

    expect do
      connector.perform
    end.to raise { Net::IMAP::NoResponseError }
  end
end
