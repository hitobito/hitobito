# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require "spec_helper"

describe Imap::Mail do
  include Mails::ImapMailsSpecHelper
  describe "#list_bounce?" do
    let(:bounce_imap_mail) { Imap::Mail.new }
    let(:bounce_mail) { Mail.read_from_string(Rails.root.join("spec", "fixtures", "email", "list_bounce.eml").read) }

    before do
      allow(bounce_imap_mail).to receive(:mail).and_return(bounce_mail)
    end

    it "has assumptions" do
      expect(bounce_imap_mail).to be_bounce
    end

    it "is a list-bounce if it is bounced and a hitobito message uid is present" do
      expect(bounce_imap_mail).to be_bounce
      expect(bounce_imap_mail.bounce_hitobito_message_uid).to be_present

      expect(bounce_imap_mail).to be_list_bounce
    end

    it "is a list-bounce without hitobito message uid" do
      body = bounce_mail.body.raw_source.gsub("X-Hitobito-Message-UID: a15816bbd204ba20", "")
      expect(bounce_mail.body).to receive(:raw_source).and_return(body)

      expect(bounce_imap_mail).to be_bounce
      expect(bounce_imap_mail).not_to be_list_bounce
    end

    it "knows the diagnostic code of the bounce" do
      expect(bounce_imap_mail.diagnostic_code).to match(/unknown user/)
    end
  end

  describe "X-Original-To header" do
    let(:imap_mail) { Imap::Mail.build(imap_fetch_data) }
    let(:imap_fetch_data) do
      instance_double("Net::Imap::FetchData", attr: {"RFC822" => @raw_mail})
    end
    let(:raw_mail) { Rails.root.join("spec", "fixtures", "email", "list.eml").read }

    it "gets first header if multiple present" do
      add_headers =
        "X-Original-To: list@hitobito.example.com\r\n" \
        "X-Original-To: another@example.com\r\n" \
        "X-Original-To: evenmore@example.com\r\n"
      @raw_mail = add_headers + raw_mail

      expect(imap_mail.original_to).to eq("list@hitobito.example.com")
    end

    it "gets header if only one present" do
      add_headers =
        "X-Original-To: list@hitobito.example.com\r\n"
      @raw_mail = add_headers + raw_mail

      expect(imap_mail.original_to).to eq("list@hitobito.example.com")
    end
  end
end
