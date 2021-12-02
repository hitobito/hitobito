# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingLists::BulkMail::ImapMailValidator do
  include MailingLists::ImapMailsHelper

  let(:mailing_list) { mailing_lists(:leaders) }
  let(:mail_log) { class_double(MailLog) }

  before do
    allow(Truemail).to receive(:valid?).and_call_original
  end

  describe '#valid_mail?' do
    context 'validating headers' do
      let(:plain_body_mail) { imap_mail(plain_body: false) }
      it 'return true if X-Original-To header present' do
        plain_body_mail.mail.header['X-Original-To'] = 'spacex@to.example.com'

        validator = described_class.new(plain_body_mail)

        expect(validator.valid_mail?).to eq(true)
      end

      it 'return true if email recipient header present' do
        # email_to is already mocked
        validator = described_class.new(plain_body_mail)

        expect(validator.valid_mail?).to eq(true)
      end

      it 'return true if multiple email recipient header present' do
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
        plain_body_mail = imap_mail(plain_body: false)

        # set invalid sender
        plain_body_mail.net_imap_mail.attr['ENVELOPE'].sender[0].mailbox = ''
        plain_body_mail.net_imap_mail.attr['ENVELOPE'].sender[0].host = ''

        validator = described_class.new(plain_body_mail)

        expect(validator.sender_valid?).to eq(false)
      end

      it 'returns true if sender valid' do
        plain_body_mail = imap_mail(plain_body: false)

        # already mocked
        validator = described_class.new(plain_body_mail)

        expect(validator.sender_valid?).to eq(false)
      end
    end
  end

  describe '#processed_before?' do
    it 'returns false if already processed' do
      plain_body_mail = imap_mail(plain_body: false)

      mail_log = MailLog.new(
        mail_hash: plain_body_mail.hash,
        status: :retrieved
      )

      expect(mail_log).to receive(:find_by).with(mail_hash: plain_body_mail.hash).and_return(mail_log).once

      validator = described_class.new(plain_body_mail)

      expect(validator.processed_before?).to eq(true)
    end

    it 'returns true if mail was not processed before' do
      plain_body_mail = imap_mail(plain_body: false)

      expect(mail_log).to receive(:find_by).with(mail_hash: plain_body_mail.hash).and_return(nil).once

      validator = described_class.new(plain_body_mail)

      expect(validator.processed_before?).to eq(true)
    end
  end

  describe '#sender_allowed?' do
    # TODO: Finish both testcases
    it 'validates that sender is allowed' do
      plain_body_mail = imap_mail(plain_body: false)

      validator = described_class.new(plain_body_mail)

      expect(validator.sender_allowed?(mailing_list)).to eq(true)
    end

    it 'validates that sender is unallowed' do
      plain_body_mail = imap_mail(plain_body: false)

      validator = described_class.new(plain_body_mail)

      expect(validator.sender_allowed?(mailing_list)).to eq(false)
    end
  end

end
