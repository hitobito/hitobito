# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Imap::Mail do
  describe '#list_bounce?' do
    let(:bounce_imap_mail) { Imap::Mail.new }
    let(:bounce_mail) { Mail.read_from_string(File.read(Rails.root.join('spec', 'fixtures', 'email', 'list_bounce.eml'))) }

    before do
      allow(bounce_imap_mail).to receive(:mail).and_return(bounce_mail)
    end

    it 'is bounce mail if hitobito message uid and mailer deamon in return-path' do
      expect(bounce_imap_mail.list_bounce?).to eq(true)
    end

    it 'is bounce mail if hitobito message uid and return-path blank' do
      bounce_mail.header['Return-Path'] = '<>'

      expect(bounce_imap_mail.list_bounce?).to eq(true)
    end

    it 'is not bounce mail if return path not mailer daemon' do
      bounce_mail.header['Return-Path'] = '<sender@example.com>'

      expect(bounce_imap_mail.list_bounce?).to eq(false)
    end

    it 'is not bounce mail if no hitobito message uid' do
      body = bounce_mail.body.raw_source.gsub('X-Hitobito-Message-UID: a15816bbd204ba20', '')
      expect(bounce_mail.body).to receive(:raw_source).and_return(body)

      expect(bounce_imap_mail.list_bounce?).to eq(false)
    end
  end
end
