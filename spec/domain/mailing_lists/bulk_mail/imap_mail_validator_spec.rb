# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingLists::BulkMail::ImapMailValidator do
  include MailingLists::ImapMailsHelper

  let(:mailing_list) { mailing_lists(:leaders) }
  let(:imap_mail) { built_imap_mail(plain_body: false) }
  let(:validator) { described_class.new(imap_mail) }
  let(:top_leader) { people(:top_leader) }

  before do
    allow(Truemail).to receive(:valid?).and_call_original
  end

  describe '#valid_mail?' do
    context 'validating headers' do
      it 'return true if X-Original-To header present' do
        imap_mail.mail.header['X-Original-To'] = 'spacex@example.com'

        expect(validator.valid_mail?).to eq(true)
      end

      it 'return true if email recipient header present' do
        # email_to is already mocked
        expect(validator.valid_mail?).to eq(true)
      end

      it 'return true if multiple email recipient header present' do
        imap_mail.mail.header['X-Original-To'] = 'spacex@example.com'
        imap_mail.mail.header['X-Original-To'] = 'spacey@example.com'

        expect(validator.valid_mail?).to eq(true)
      end

      it 'returns false if mandatory headers not present' do
        # remove mandatory headers
        imap_mail.mail.header['X-Original-To'] = ''
        imap_mail.net_imap_mail.attr['ENVELOPE'].to[0].mailbox = ''
        imap_mail.net_imap_mail.attr['ENVELOPE'].to[0].host = ''

        expect(validator.valid_mail?).to eq(false)
      end
    end

    context 'sender validation' do
      it 'returns false if sender invalid' do
        # set invalid sender
        imap_mail.net_imap_mail.attr['ENVELOPE'].sender[0].mailbox = ''
        imap_mail.net_imap_mail.attr['ENVELOPE'].sender[0].host = ''

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
      MailLog.create!(
        mail_hash: imap_mail.hash,
        status: :retrieved
      )

      expect(validator.processed_before?).to eq(true)
    end

    it 'returns false if mail was not processed before' do
      # no mail log mock needec, hence not present
      expect(validator.processed_before?).to eq(false)
    end
  end

  describe '#sender_allowed?' do
    it 'validates that sender is allowed when additional sender' do
      sender_email = imap_mail.sender_email
      mailing_list.additional_sender = sender_email

      expect(validator.sender_allowed?(mailing_list)).to eq(true)
    end

    it 'validates that sender is allowed when sender is group email' do
      sender_email = imap_mail.sender_email

      mailing_list.group.additional_emails << AdditionalEmail.new(email: sender_email)

      expect(validator.sender_allowed?(mailing_list)).to eq(true)
    end

    it 'validates that sender is allowed when sender is additional group sender' do
      sender_email = imap_mail.sender_email

      mailing_list.group.email = sender_email

      expect(validator.sender_allowed?(mailing_list)).to eq(true)
    end

    it 'validates that sender is list admin' do
      imap_mail.net_imap_mail.attr['ENVELOPE'].sender[0].mailbox = 'top_leader'
      imap_mail.net_imap_mail.attr['ENVELOPE'].sender[0].host = 'example.com'

      expect(validator.sender_allowed?(mailing_list)).to eq(true)
    end

    it 'validates that sender is allowed when anyone may post' do
      mailing_list.anyone_may_post = true

      expect(validator.sender_allowed?(mailing_list)).to eq(true)
    end

    it 'validates that sender is allowed when subscribers may post and sender is list member' do
      bottom_member = people(:bottom_member)

      imap_mail.net_imap_mail.attr['ENVELOPE'].sender[0].mailbox = 'bottom_member'
      imap_mail.net_imap_mail.attr['ENVELOPE'].sender[0].host = 'example.com'

      mailing_list.subscribers_may_post = true
      mailing_list.subscriptions.create(subscriber: bottom_member)

      expect(validator.sender_allowed?(mailing_list)).to eq(true)
    end

    it 'validates that sender is unallowed when none of the above validates' do
      # unallowed sender already mocked
      expect(validator.sender_allowed?(mailing_list)).to eq(false)
    end
  end
end
