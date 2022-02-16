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
      MailLog.create!(mail_hash: 'abcd42', message: Message::BulkMail.create!(subject: '42 is the Answer'))

      expect do
        retriever.perform
      end.to raise_error(MailingLists::BulkMail::MailProcessedBeforeError)
    end
  end

  context 'invalid mail' do
    it 'does not process invalid email and deletes it from imap inbox' do
      expect(imap_mail_validator).to receive(:valid_mail?).and_return(false)
      expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)

      Rails.logger.should_receive(:info)
        .with('BulkMail Retriever: Ignored invalid email from dude@hitobito.example.com')

      retriever.perform
    end
  end

  context 'process mail' do
    it 'does not process mail if no mailing list can be assigned' do
      allow(mail42).to receive(:original_to).and_return('nolist@localhost')
      expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)

      Rails.logger.should_receive(:info)
        .with('BulkMail Retriever: Ignored email from dude@hitobito.example.com for unknown list nolist@localhost')

      expect do
        retriever.perform
      end.to change { Message::BulkMail.count }.by(1)
        .and change { MailLog.count }.by(1)
        .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(0)

      mail_log = MailLog.find_by(mail_hash: 'abcd42')
      expect(mail_log.status).to eq('unknown_recipient')
      expect(mail_log.mail_from).to eq('dude@hitobito.example.com')

      message = mail_log.message
      expect(message.subject).to eq('Mail 42')
      expect(message.state).to eq('failed')
      expect(message.state).to eq('failed')
    end

    it 'does not process mail for mailing list of archived group' do
      groups(:top_layer).update!(archived_at: 30.days.ago)
      expect(mail42).to receive(:original_to).and_return('leaders@localhost:3000')
      expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)

      expect do
        retriever.perform
      end.to change { Message::BulkMail.count }.by(1)
        .and change { MailLog.count }.by(1)
        .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(0)

      mail_log = MailLog.find_by(mail_hash: 'abcd42')
      expect(mail_log.status).to eq('unknown_recipient')
      expect(mail_log.mail_from).to eq('dude@hitobito.example.com')

      message = mail_log.message
      expect(message.subject).to eq('Mail 42')
      expect(message.state).to eq('failed')
      expect(message.state).to eq('failed')
    end

    it 'does not process mail if sender is not allowed to send to list' do
      expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)
      expect(imap_mail_validator).to receive(:sender_allowed?).and_return(false)

      Rails.logger.should_receive(:info).with('BulkMail Retriever: Rejecting email from dude@hitobito.example.com for list leaders@localhost')

      expect do
        retriever.perform
      end.to change { Message::BulkMail.count }.by(1)
        .and change { MailLog.count }.by(1)
        .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(0)
        .and change { Delayed::Job.where('handler like "%MailingLists::BulkMail::SenderRejectedMessageJob%"').count }.by(1)

      mail_log = MailLog.find_by(mail_hash: 'abcd42')
      expect(mail_log.status).to eq('sender_rejected')
      expect(mail_log.mail_from).to eq('dude@hitobito.example.com')

      message = mail_log.message
      expect(message.subject).to eq('Mail 42')
      expect(message.state).to eq('failed')
    end

    it 'does process mail and enqueues job for mail delivery' do
      expect(mail42).to receive(:original_to).and_return('leaders@localhost:3000')
      expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)
      expect(imap_mail_validator).to receive(:sender_allowed?).and_return(true)

      expect do
        retriever.perform
      end.to change { Message::BulkMail.count }.by(1)
        .and change { MailLog.count }.by(1)
        .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(1)
        .and change { Delayed::Job.where('handler like "%MailingLists::BulkMail::SenderRejectedMessageJob%"').count }.by(0)

      mail_log = MailLog.find_by(mail_hash: 'abcd42')
      expect(mail_log.status).to eq('retrieved')
      expect(mail_log.mail_from).to eq('dude@hitobito.example.com')

      message = mail_log.message
      expect(message.subject).to eq('Mail 42')
      expect(message.state).to eq('pending')
    end
  end

  context 'imap mail server errors' do
    # it 'terminates without error if imap server temporarly unreachable' do
    # # expect error to be thrown
    # expect(imap_connector).to receive(:fetch_mail_uids).with(:inbox).and_return([42])

    # # TODO: Maybe ignore some exceptions and create log entries instead. (hitobito#1493)
    # expect do
    # retriever.perform
    # end.to raise { Net::IMAP::NoResponseError }
    # end

    # it 'raises exception if unknown error' do
    # # raise unexpected EOFError
    # expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(EOFError)

    # expect do
    # retriever.perform
    # end.to raise { EOFError }
    # end
  end

  private

  def imap_mail(uid)
    mail = Imap::Mail.new
    allow(mail).to receive(:uid).and_return(uid)
    allow(mail).to receive(:subject).and_return('Mail 42')
    allow(mail).to receive(:original_to).and_return('leaders@localhost')
    allow(mail).to receive(:hash).and_return('abcd42')
    allow(mail).to receive(:sender_email).and_return('dude@hitobito.example.com')
    allow(mail).to receive(:raw_source).and_return('raw-source')
    mail
  end

end
