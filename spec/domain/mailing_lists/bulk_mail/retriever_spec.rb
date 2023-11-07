# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingLists::BulkMail::Retriever do
  include MailingLists::ImapMailsSpecHelper

  let(:retriever) { described_class.new }
  let(:imap_connector) { instance_double(Imap::Connector) }
  let(:mailing_list) { mailing_lists(:leaders) }
  let(:imap_mail_validator) { instance_double(MailingLists::BulkMail::ImapMailValidator) }

  before do
    allow(retriever).to receive(:validator).and_return(imap_mail_validator)
    allow(retriever).to receive(:imap).and_return(imap_connector)
    allow(imap_connector).to receive(:fetch_mail_by_uid).with(42, :inbox).and_return(imap_mail)
    allow(imap_connector).to receive(:fetch_mail_uids).with(:inbox).and_return([42])
    allow(imap_mail_validator).to receive(:valid_mail?).and_return(true)
    allow(imap_mail_validator).to receive(:processed_before?).and_return(false)
  end

  context 'mails subject' do

    let(:imap_mail) { build_imap_mail(42, 'Mail 42') }

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

        expect(Rails.logger).to receive(:info)
          .with('BulkMail Retriever: Ignored invalid email from dude@hitobito.example.com (invalid sender e-mail or no sender name present)')

        retriever.perform
      end
    end

    context 'process mail' do
      it 'does not process mail if no mailing list can be assigned' do
        allow(imap_mail).to receive(:original_to).and_return('nolist@localhost')
        expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)

        expect(Rails.logger).to receive(:info)
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
        expect(imap_mail).to receive(:original_to).and_return('leaders@localhost:3000')
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

        expect(Rails.logger).to receive(:info)
          .with("BulkMail Retriever: Rejecting email from dude@hitobito.example.com for list leaders@#{Settings.email.list_domain}")

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
        expect(message.raw_source).to be_present
      end

      it 'does process mail and enqueues job for mail delivery' do
        expect(imap_mail).to receive(:original_to).and_return('leaders@localhost:3000')
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

      it 'does not process mail if no sender name' do
        expect(imap_mail).to receive(:original_to).and_return('leaders@localhost:3000')
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

      it 'terminates without error if imap server temporarly unreachable' do
        expect(imap_connector).to receive(:config).with(:address).and_return('imap.example.com')
        expect(imap_connector).to receive(:fetch_mail_uids).with(:inbox).and_raise(Errno::EADDRNOTAVAIL)

        expect(Rails.logger).to receive(:info)
          .with('BulkMail Retriever: cannot connect to IMAP server imap.example.com, terminating.')

        retriever.perform
      end

      it 'raises exception if non connection error' do
        expect(imap_connector).to receive(:fetch_mail_uids).with(:inbox).and_raise(Net::IMAP::NoResponseError)

        expect do
          retriever.perform
        end.to raise_error { Net::IMAP::NoResponseError }
      end
    end

    context 'bounce message' do
      let(:imap_mail) { Imap::Mail.new }
      let(:bounce_mail) { Mail.read_from_string(File.read(Rails.root.join('spec', 'fixtures', 'email', 'list_bounce.eml'))) }

      before do
        allow(imap_mail).to receive(:original_to).and_return('leaders@localhost')
        allow(imap_mail).to receive(:mail).and_return(bounce_mail)
        allow(imap_mail).to receive(:sender_email).and_return('MAILER-DAEMON@example.com')
        allow(imap_mail).to receive(:subject).and_return('Undelivered Mail Returned to Sender')
      end

      it 'forwards bounce message to sender' do
        expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)

        expect do
          retriever.perform
        end.to change { Message::BulkMailBounce.count }.by(1)
          .and change { Message::BulkMail.count }.by(0)
          .and change { MailLog.count }.by(1)
          .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(0)
          .and change { Delayed::Job.where('handler like "%MailingLists::BulkMail::BounceMessageForwardJob%"').count }.by(1)
      end
    end

    context 'auto response message' do
      let(:imap_mail) { Imap::Mail.new }
      let(:auto_response) { Mail.read_from_string(File.read(Rails.root.join('spec', 'fixtures', 'email', 'autoresponse.eml'))) }

      before do
        allow(imap_mail).to receive(:hash).and_return('abcd42')
        allow(imap_mail).to receive(:original_to).and_return('leaders@localhost')
        allow(imap_mail).to receive(:mail).and_return(auto_response)
        allow(imap_mail).to receive(:sender_email).and_return('David Hasselhof <david.hasselhof@example.com>')
        allow(imap_mail).to receive(:subject).and_return('Automatische Antwort: Foundation for Law and Government')
      end

      it 'ignores auto response messages' do
        expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)

        expect do
          retriever.perform
        end.to change { Message::BulkMailBounce.count }.by(0)
          .and change { Message::BulkMail.count }.by(0)
          .and change { MailLog.count }.by(1)
          .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(0)
          .and change { Delayed::Job.where('handler like "%MailingLists::BulkMail::BounceMessageForwardJob%"').count }.by(0)

          mail_log = MailLog.find_by(mail_hash: 'abcd42')
          expect(mail_log.status).to eq('auto_response_rejected')
        end
    end

    it 'does process mail with long subject and enqueues job for mail delivery' do
      imap_mail = build_imap_mail(42, 300.times.map{ "a" }.join(''))
      allow(imap_connector).to receive(:fetch_mail_by_uid).with(42, :inbox).and_return(imap_mail)

      expect(imap_mail).to receive(:original_to).and_return('leaders@localhost:3000')
      expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)
      expect(imap_mail_validator).to receive(:sender_allowed?).and_return(true)

      expect do
        retriever.perform
      end.to change { Message::BulkMail.count }
               .by(1)
               .and change { MailLog.count }.by(1)
               .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(1)
               .and change { Delayed::Job.where('handler like "%MailingLists::BulkMail::SenderRejectedMessageJob%"').count }.by(0)

      mail_log = MailLog.find_by(mail_hash: 'abcd42')
      expect(mail_log.status).to eq('retrieved')
      expect(mail_log.mail_from).to eq('dude@hitobito.example.com')

      message = mail_log.message
      expect(message.subject).to eq(256.times.map{ "a" }.join(''))
      expect(message.state).to eq('pending')
    end

    it 'processes even invalid mail with overly long subject and enqueues job for mail delivery' do
      imap_mail = build_imap_mail(42, 1000.times.map{ "a" }.join(''))
      allow(imap_connector).to receive(:fetch_mail_by_uid).with(42, :inbox).and_return(imap_mail)

      expect(imap_mail).to receive(:original_to).and_return('leaders@localhost:3000')
      expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)
      expect(imap_mail_validator).to receive(:sender_allowed?).and_return(true)

      expect do
        retriever.perform
      end.to change { Message::BulkMail.count }
               .by(1)
               .and change { MailLog.count }.by(1)
               .and change { Delayed::Job.where('handler like "%Messages::DispatchJob%"').count }.by(1)
               .and change { Delayed::Job.where('handler like "%MailingLists::BulkMail::SenderRejectedMessageJob%"').count }.by(0)

      mail_log = MailLog.find_by(mail_hash: 'abcd42')
      expect(mail_log.status).to eq('retrieved')
      expect(mail_log.mail_from).to eq('dude@hitobito.example.com')

      message = mail_log.message
      expect(message.subject).to eq(256.times.map{ "a" }.join(''))
      expect(message.state).to eq('pending')
    end

    it 'does process mail with utf-8 encoding and enqueues job for mail delivery' do
      imap_mail = build_imap_mail(42, "Anlass hinzugefügt 😜🥶明天回报")
      allow(imap_connector).to receive(:fetch_mail_by_uid).with(42, :inbox).and_return(imap_mail)

      expect(imap_mail).to receive(:original_to).and_return('leaders@localhost:3000')
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
      expect(message.subject).to eq("Anlass hinzugefügt 😜🥶明天回报")
      expect(message.state).to eq('pending')
    end

    it 'does process mail with wrong encoding and enqueues job for mail delivery' do
      imap_mail = build_imap_mail(42, "Anlass hinzugef\xFcgt".dup.force_encoding('ASCII-8BIT'))
      allow(imap_connector).to receive(:fetch_mail_by_uid).with(42, :inbox).and_return(imap_mail)

      expect(imap_mail).to receive(:original_to).and_return('leaders@localhost:3000')
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
      expect(message.subject).to eq("Anlass hinzugef�gt")
      expect(message.state).to eq('pending')
    end

    it 'does process mail with empty subject and enqueues job for mail delivery' do
      imap_mail = build_imap_mail(42, nil)
      allow(imap_connector).to receive(:fetch_mail_by_uid).with(42, :inbox).and_return(imap_mail)

      expect(imap_mail).to receive(:original_to).and_return('leaders@localhost:3000')
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
      expect(message.subject).to eq(nil)
      expect(message.state).to eq('pending')
    end
  end

  private

  def build_imap_mail(uid, subject)
    mail = Imap::Mail.new
    allow(mail).to receive(:uid).and_return(uid)
    allow(mail).to receive(:subject).and_return(subject)
    allow(mail).to receive(:original_to).and_return('leaders@localhost')
    allow(mail).to receive(:hash).and_return('abcd42')
    allow(mail).to receive(:sender_email).and_return('dude@hitobito.example.com')

    imap_mail = Mail.read_from_string(File.read(Rails.root.join('spec', 'fixtures', 'email', 'list.eml')))
    allow(mail).to receive(:mail).and_return(imap_mail)
    mail
  end

end
