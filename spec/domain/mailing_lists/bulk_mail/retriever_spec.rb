# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingLists::BulkMail::Retriever do
  include MailingLists::ImapMailsHelper

  let(:retriever) { described_class.new }
  let(:imap_connector) { instance_double(Imap::Connector) }
  let(:mailing_list) { mailing_lists(:leaders) }
  let(:imap_mail_validator) { instance_double(MailingLists::BulkMail::ImapMailValidator) }
  let(:mail42) { imap_mail(42) }

  before do
    allow(retriever).to receive(:validator).and_return(imap_mail_validator)
    allow(retriever).to receive(:imap).and_return(imap_connector)
    allow(imap_connector).to receive(:fetch_mail_by_uid).with(42, :inbox).and_return(mail42)
    allow(imap_connector).to receive(:fetch_mail_uids).with(:inbox).and_return([42])
    allow(imap_mail_validator).to receive(:valid_mail?).and_return(true)
    allow(imap_mail_validator).to receive(:processed_before?).and_return(false)
  end

  context 'mail processed before' do
    it 'moves mail to failed imap folder and raises exception' do
      expect(imap_mail_validator).to receive(:processed_before?).and_return(true)
      expect(imap_connector).to receive(:move_by_uid).with(42, :inbox, :failed)
      expect(imap_mail_validator).to receive(:valid_mail?).never
      expect(imap_connector).to receive(:delete_by_uid).never
      MailLog.create!(mail_hash: 'abcd42')

      expect do
        retriever.perform
      end.to raise_error(MailingLists::BulkMail::MailProcessedBeforeError)
    end
  end

  context 'invalid mail' do
    it 'does not process invalid email and deletes it from imap inbox' do
      expect(imap_mail_validator).to receive(:valid_mail?).and_return(false)
      expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)
      # TODO: check for log entry

      retriever.perform
    end
  end

  context 'process mail' do
    it 'does not process mail if no mailing list can be assigned' do
      expect(mail42).to receive(:original_to).and_return('nolist@localhost:3000')
      expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)

      expect do
        retriever.perform
      end.to change { Message::BulkMail.count }.by(1)
        .and change { MailLog.count }.by(1)
        .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(0)

      mail_log = MailLog.find_by(mail_hash: 'abcd42')
      expect(mail_log.status).to eq('unknown_recipient')
      expect(mail_log.mail_from).to eq('dude@hitobito.example.com')
    end

    it 'does not process mail if sender is not allowed to send to list' do
    end

    it 'does process mail and enqueues job for mail delivery' do
    end
  end

  # it 'receives mail and enqueues dispatch' do
    # # mock fetched mails
    # imap_mail = new_imap_mail

    # # mock imap_connector calls
    # expect(imap_connector).to receive(:fetch_mail_uids).with(:inbox).and_return([42])
    # expect(imap_connector).to receive(:fetch_mail_by_uid).with(:inbox, 42).and_return([imap_mail])
    # expect(imap_connector).to receive(:delete_by_uid).with(:inbox, 42).once

    # expect do
      # retriever.perform
    # end.to change { mailing_list.messages.count }.by(1)
                 # .and change { MailLog.count }.by(1)
                 # .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(1)

    # # check message values
    # message = mailing_list.messages.first
    # expect(message.subject).to eq('Testflight from 24.4.2021')
    # expect(message.sender).to eq('from@example.com')
    # expect(message.state).to eq('pending')

    # mail_log = message.mail_log
    # mail_hash = Digest::MD5.new.hexdigest(imap_mail.mail.raw_source)
    # expect(mail_log.mail_hash).to eq(mail_hash)
    # expect(mail_log.mailing_list_name).to eq(mailing_list.name)
    # expect(mail_log.state).to eq('retrieved')
  # end

  # it 'terminates if imap server not reachable' do
    # # expect error to be thrown
    # expect(imap_connector).to receive(:fetch_mail_uids).with(:inbox).and_return([42])

    # # TODO: Maybe ignore some exceptions and create log entries instead. (hitobito#1493)
    # expect do
      # retriever.perform
    # end.to raise { Net::IMAP::NoResponseError }
  # end

  # it 'drops mail if cannot be assigned to mailing list' do
    # # mock fetched mails
    # imap_mail = new_imap_mail

    # # mock imap_connector calls
    # expect(imap_connector).to receive(:fetch_mail_uids).with(:inbox).and_return([42])
    # expect(imap_connector).to receive(:fetch_mail_by_uid).with(:inbox, 42).and_return([imap_mail])
    # expect(imap_connector).to receive(:delete_by_uid).with(:inbox, 42).once

    # expect do
      # retriever.perform
    # end.to change { mailing_list.messages.count }.by(0)
           # .and change { MailLog.count }.by(1)
           # .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(0)

    # message = mailing_list.messages.first
    # expect(message.subject).to eq('Supermail report')
    # expect(message.sender).to eq('superman')

    # mail_log = message.mail_log
    # mail_hash = Digest::MD5.new.hexdigest(imap_mail.mail.raw_source)
    # expect(mail_log.mail_hash).to eq(mail_hash)
    # expect(mail_log.mailing_list_name).to eq(mailing_list.name)
    # expect(mail_log.state).to eq('unknown_recipient')
  # end

  # it 'replies with error mail if sender not allowed to send to mailing list' do
    # imap_mails = []
    # expect(imap_connector).to receive(:fetch_mail_uids).with(:inbox).and_return([42])
    # expect(imap_connector).to receive(:fetch_mail_by_uid).with(:inbox, 42).and_return(imap_mails)
    # expect(imap_connector).to receive(:delete_by_uid).with(:inbox, 42).once

    # expect(retriever).to receive(:reject_not_allowed).once

    # expect do
      # retriever.perform
    # end.to change { mailing_list.messages.count }.by(1)
                 # .and change { MailLog.count }.by(1)
                 # .and change { Delayed::Job.where('handler like "%Messages::BulkMailNotificationJob%"').count }.by(1)
                 # .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(0)

    # message = mailing_list.messages.first
    # mail_log = message.mail_log
    # mail_hash = Digest::MD5.new.hexdigest(imap_mail.mail.raw_source)
    # expect(mail_log.mail_hash).to eq(mail_hash)
    # expect(mail_log.mailing_list_name).to eq(mailing_list.name)
    # expect(mail_log.state).to eq('unknown_recipient')
  # end

  # it 'skips if no new mail in mailbox available' do
    # # don't mock considering no mails in inbox
    # imap_mails = []

    # expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mails)
    # expect(imap_connector).not_to receive(:delete_by_uid)
    # expect(imap_connector).not_to receive(:move_by_uid)

    # expect do
      # retriever.perform
    # end
    # .to change { mailing_list.messages.count }.by(0)
    # .and change { MailLog.count }.by(0)
    # .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(0)
  # end

  # it 'raises exception if unknown error' do
    # # raise unexpected EOFError
    # expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(EOFError)

    # expect do
      # retriever.perform
    # end.to raise { EOFError }
  # end

  # it 'moves mail to failed if MailLog for Mail exists' do
    # # mock fetched mails
    # imap_mail = new_imap_mail

    # expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return([imap_mail])
    # expect(imap_connector).to receive(:move_by_uid).with(42, :inbox, :failed)

    # expect do
      # retriever.perform
    # end.to raise { Messages::Errors::MailProcessedBefore }
      # .to change { mailing_list.messages.count }.by(0)
      # .and change { MailLog.count }.by(0)
      # .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(0)

    # message = mailing_list.messages.first
    # mail_log = message.mail_log
    # mail_hash = Digest::MD5.new.hexdigest(imap_mail.mail.raw_source)
    # expect(mail_log.mail_hash).to eq(mail_hash)
    # expect(mail_log.mailing_list_name).to eq(mailing_list.name)
    # expect(mail_log.state).to eq('retrieved')
  # end
  private

  def imap_mail(uid)
    mail = Imap::Mail.new
    allow(mail).to receive(:uid).and_return(uid)
    allow(mail).to receive(:subject).and_return('Mail 42')
    allow(mail).to receive(:original_to).and_return('leaders@localhost:3000')
    allow(mail).to receive(:hash).and_return('abcd42')
    allow(mail).to receive(:sender_email).and_return('dude@hitobito.example.com')
    allow(mail).to receive(:raw_source).and_return('raw-source')
    mail
  end

end
