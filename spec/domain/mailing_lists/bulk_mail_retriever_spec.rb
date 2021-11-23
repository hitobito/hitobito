# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingLists::BulkMailRetriever do
  include MailingLists::ImapMailsHelper

  let(:retriever) { described_class.new }
  let(:imap_connector) { instance_double(Imap::Connector) }
  let(:mailing_list) { mailing_lists(:leaders) }

  it 'receives mail and enqueues dispatch' do
    # mock fetched mails
    imap_mail = new_imap_mail

    # mock imap_connector calls
    expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return([imap_mail])
    expect(imap_connector).to receive(:delete_by_uid).with(:inbox, 42).once

    expect do
      retriever.perform
    end.to change { mailing_list.messages.count }.by(1)
                 .and change { MailLog.count }.by(1)
                 .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(1)

    # check message values
    message = mailing_list.messages.first
    expect(message.subject).to eq('Testflight from 24.4.2021')
    expect(message.sender).to eq('from@example.com')
    expect(message.state).to eq('pending')
  end

  # TODO: Adjust the following test cases

  it 'terminates if imap server not reachable' do
    # expect error to be thrown
    expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(Net::IMAP::NoResponseError)


    # TODO: Maybe ignore some execptions and create log entries instead. (hitobito#1493)
    expect do
      retriever.perform
    end.to raise { Net::IMAP::NoResponseError }
  end

  it 'drops mail if cannot be assigned to mailing list' do
    # mock fetched mails
    imap_mails = [
      new_imap_mail
    ]

    # mock imap_connector calls
    expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mails)
    expect(imap_connector).to receive(:delete_by_uid).with(:inbox, :mail_uid).once

    # execute 'job'
    expect do
      retriever.perform
    end.to change { mailing_list.messages.count }.by(0)
           .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(0)

    expect(retriever).to receive(:reject_mail)

    message = mailing_list.messages.first
    expect(message.subject).to eq('Supermail report')
    expect(message.sender).to eq('superman')
  end

  it 'replies with error mail if sender not allowed to send to mailing list' do
    imap_mails = []
    expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mails)
    expect(imap_connector).to receive(:delete).with(:mail_id)

    expect do
      retriever.perform
    end.to change { mailing_list.messages.count }.by(0)
                 .and change { MailLog.count }.by(1)
                 .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(0)
    expect(retriever).to receive(:unallowed_sender)
  end

  it 'skips if no new mail in mailbox available' do
    imap_mails = []
    expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mails)
    expect(imap_connector).to receive(:delete).with(:mail_id)

    expect do
      retriever.perform
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
      retriever.perform
    end.to raise { Net::IMAP::NoResponseError }
  end
end
