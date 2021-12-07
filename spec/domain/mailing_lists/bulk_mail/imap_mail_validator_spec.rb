# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingLists::BulkMail::ImapMailValidator do
  include MailingLists::ImapMailsHelper

  let(:validator) { described_class.new(imap_mail) }
  let(:imap_mail) { built_imap_mail(plain_body: false) }
  let(:mailing_list) { mailing_lists(:leaders) }
  let(:top_leader) { people(:top_leader) }

  before do
    allow(Truemail).to receive(:valid?).and_call_original
  end

  describe '#valid_mail?' do
    context 'validating headers' do
      it 'is valid if X-Original-To header present' do
        imap_mail.mail.header['X-Original-To'] = 'spacex@example.com'

        expect(validator.valid_mail?).to eq(true)
      end

      it 'is valid if email recipient header present' do
        expect(validator.valid_mail?).to eq(true)
      end

      it 'is valid if multiple email recipient header present' do
        imap_mail.mail.header['X-Original-To'] = 'spacex@example.com'
        imap_mail.mail.header['X-Original-To'] = 'spacey@example.com'

        expect(validator.valid_mail?).to eq(true)
      end

      it 'is not valid if mandatory headers not present' do
        # remove all mandatory headers
        imap_mail.mail.header['X-Original-To'] = ''
        imap_mail.net_imap_mail.attr['ENVELOPE'].to[0].mailbox = ''
        imap_mail.net_imap_mail.attr['ENVELOPE'].to[0].host = ''

        expect(validator.valid_mail?).to eq(false)
      end
    end

    context 'sender validation' do
      it 'is not valid if no sender present' do
        imap_mail.net_imap_mail.attr['ENVELOPE'].sender[0].mailbox = ''
        imap_mail.net_imap_mail.attr['ENVELOPE'].sender[0].host = ''

        expect(validator.valid_mail?).to eq(false)
      end

      it 'is valid if valid sender present' do
        expect(validator.valid_mail?).to eq(true)
      end
    end
  end

  describe '#processed_before?' do
    it 'returns true if imap mail processed before' do
      MailLog.create!(
        mail_hash: imap_mail.hash,
        status: :retrieved
      )

      expect(validator.processed_before?).to eq(true)
    end

    it 'returns false if imap mail was not processed before' do
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

    it 'validates that sender is allowed if list admin' do
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

    it 'validates that sender not allowed' do
      expect(validator.sender_allowed?(mailing_list)).to eq(false)
    end
  end
end
