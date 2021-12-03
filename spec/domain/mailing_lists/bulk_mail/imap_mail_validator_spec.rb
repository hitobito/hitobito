# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingLists::BulkMail::ImapMailValidator do
  include MailingLists::ImapMailsHelper

  let(:mailing_list) { mailing_lists(:leaders) }
  let(:plain_body_mail) { imap_mail(plain_body: false) }
  let(:validator) { described_class.new(plain_body_mail) }

  before do
    allow(Truemail).to receive(:valid?).and_call_original
  end

  describe '#valid_mail?' do
    context 'validating headers' do
      it 'return true if X-Original-To header present' do
        plain_body_mail.mail.header['X-Original-To'] = 'spacex@example.com'

        validator = described_class.new(plain_body_mail)

        expect(validator.valid_mail?).to eq(true)
      end

      it 'return true if email recipient header present' do
        # email_to is already mocked
        expect(validator.valid_mail?).to eq(true)
      end

      it 'return true if multiple email recipient header present' do
        plain_body_mail.mail.header['X-Original-To'] = 'spacex@example.com'
        plain_body_mail.mail.header['X-Original-To'] = 'spacey@example.com'

        # email_to is already mocked
        validator = described_class.new(plain_body_mail)

        expect(validator.valid_mail?).to eq(true)
      end

      it 'returns false if mandatory headers not present' do
        # remove mandatory headers
        plain_body_mail.mail.header['X-Original-To'] = ''
        plain_body_mail.net_imap_mail.attr['ENVELOPE'].to[0].mailbox = ''
        plain_body_mail.net_imap_mail.attr['ENVELOPE'].to[0].host = ''

        validator = described_class.new(plain_body_mail)

        expect(validator.valid_mail?).to eq(false)
      end
    end

    context 'sender validation' do
      it 'returns false if sender invalid' do
        # set invalid sender
        plain_body_mail.net_imap_mail.attr['ENVELOPE'].sender[0].mailbox = ''
        plain_body_mail.net_imap_mail.attr['ENVELOPE'].sender[0].host = ''

        validator = described_class.new(plain_body_mail)

        expect(validator.valid_mail?).to eq(false)
      end

      it 'returns true if sender valid' do
        # already mocked
        expect(validator.valid_mail?).to eq(true)
      end
    end
  end

  describe '#processed_before?' do
    it 'returns true if already processed' do
      mail_log = MailLog.new(
        mail_hash: plain_body_mail.hash,
        status: :retrieved
      )

      expect(MailLog).to receive(:find_by).with(mail_hash: plain_body_mail.hash).and_return(mail_log).once

      expect(validator.processed_before?).to eq(true)
    end

    it 'returns false if mail was not processed before' do
      expect(MailLog).to receive(:find_by).with(mail_hash: plain_body_mail.hash).and_return(nil).once

      expect(validator.processed_before?).to eq(false)
    end
  end

  describe '#sender_allowed?' do
    context 'sender_included?' do
      it 'validates that sender is allowed when additional sender' do
        sender_email = plain_body_mail.sender_email
        mailing_list.additional_sender = sender_email

        expect(validator.sender_allowed?(mailing_list)).to eq(true)
      end

      context 'sender_is_group_member?' do
        it 'validates that sender is allowed when sender is group email' do
          sender_email = plain_body_mail.sender_email

          mailing_list.group.additional_emails << AdditionalEmail.new(email: sender_email)

          expect(validator.sender_allowed?(mailing_list)).to eq(true)
        end

        it 'validates that sender is allowed when sender is additional group sender' do
          sender_email = plain_body_mail.sender_email

          mailing_list.group.email = sender_email

          expect(validator.sender_allowed?(mailing_list)).to eq(true)
        end
      end
    end

    context 'sender_list_administrator?' do
      it 'validates that sender is list admin' do
        sender_email = plain_body_mail.sender_email

        person = Person.new(
          email: sender_email
        )

        # TODO: Fix this.
        # expect(Person).to receive(:joins, :where, :distinct).and_return(person).once


        expect(validator.sender_allowed?(mailing_list)).to eq(true)
      end
    end

    context 'mailing_list_allowed?' do
      it 'validates that sender is allowed when anyone may post' do
        # plain_body_mail = imap_mail(plain_body: false)
        #
        # validator = described_class.new(plain_body_mail)
        #
        # expect(validator.sender_allowed?(mailing_list)).to eq(true)
      end

      it 'validates that sender is allowed when subscribers may post and sender is list member' do
        # plain_body_mail = imap_mail(plain_body: false)
        #
        # validator = described_class.new(plain_body_mail)
        #
        # expect(validator.sender_allowed?(mailing_list)).to eq(true)
      end

    end

    it 'validates that sender is unallowed when none of the above validates' do
      # plain_body_mail = imap_mail(plain_body: false)
      #
      # validator = described_class.new(plain_body_mail)
      #
      # expect(validator.sender_allowed?(mailing_list)).to eq(false)
    end

  end
end
