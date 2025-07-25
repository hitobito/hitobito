# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require "spec_helper"

describe MailingLists::BulkMail::BounceHandler do
  include Mails::ImapMailsSpecHelper

  let(:bounce_handler) { described_class.new(bounce_imap_mail, bulk_mail_bounce, mailing_list) }
  let(:mailing_list) { mailing_lists(:leaders) }
  let(:bounce_imap_mail) { Imap::BounceMail.new(imap_mail) }
  let(:imap_mail) { Imap::Mail.new }
  let(:bounce_mail) { Mail.read_from_string(Rails.root.join("spec", "fixtures", "email", "list_bounce.eml").read) }

  let(:bulk_mail_bounce) do
    Message::BulkMailBounce.create!(
      state: :pending,
      subject: "Undelivered Mail Returned to Sender"
    )
  end

  let!(:mail_log) do
    MailLog.create!(
      mail_from: "MAILER-DAEMON@example.com",
      message: bulk_mail_bounce,
      mail_hash: "abcd42"
    )
  end

  before do
    allow(bounce_imap_mail).to receive(:mail).and_return(bounce_mail)
  end

  describe "#process" do
    let(:bounce_parent) { messages(:bulk_mail) }

    it "does not process bounce if source message cannot be found" do
      body = bounce_mail.body.raw_source.gsub("X-Hitobito-Message-UID: a15816bbd204ba20", "X-Hitobito-Message-UID: unknown42")
      expect(bounce_mail.body).to receive(:raw_source).at_least(:once).and_return(body)

      expect(Rails.logger).to receive(:info)
        .with("BulkMail Retriever: Ignoring unkown or outdated bounce message for list leaders@#{Settings.email.list_domain}")

      expect do
        bounce_handler.process
      end.to change { Delayed::Job.where("handler ILIKE '%MailingLists::BulkMail::BounceMessageForwardJob%'").count }.by(0)

      mail_log = MailLog.find_by(mail_hash: "abcd42")
      expect(mail_log.status).to eq("bounce_rejected")

      expect(mail_log.reload.message).to be_nil
    end

    it "does not process bounce if source message to old" do
      messages(:mail).update_columns(created_at: DateTime.now - 26.hours)

      expect(Rails.logger).to receive(:info)
        .with("BulkMail Retriever: Ignoring unkown or outdated bounce message for list leaders@#{Settings.email.list_domain}")

      expect do
        bounce_handler.process
      end.to change { Delayed::Job.where("handler ILIKE '%MailingLists::BulkMail::BounceMessageForwardJob%'").count }.by(0)

      mail_log = MailLog.find_by(mail_hash: "abcd42")
      expect(mail_log.status).to eq("bounce_rejected")

      expect(mail_log.reload.message).to be_nil
    end

    it "processes bounce message" do
      expect(Rails.logger).to receive(:info)
        .with("BulkMail Retriever: Forwarding bounce message for list leaders@#{Settings.email.list_domain} to sender@example.com")

      expect do
        bounce_handler.process
      end.to change { Delayed::Job.where("handler ILIKE '%MailingLists::BulkMail::BounceMessageForwardJob%'").count }.by(1)

      mail_log = MailLog.find_by(mail_hash: "abcd42")
      expect(mail_log.status).to eq("retrieved")

      message = mail_log.message
      expect(message.state).to eq("pending")
      expect(message.raw_source).to eq(bounce_imap_mail.raw_source)
      expect(message.mailing_list).to be_nil
      expect(message.bounce_parent).to eq(messages(:mail))
    end

    it "records the bounce" do
      expect do
        bounce_handler.process
      end.to change(Bounce, :count).by(1)

      last_bounce = Bounce.order(:updated_at).last

      expect(bounce_mail.raw_source).to include("To: nothing@example2.com")
      expect(bounce_mail.raw_source).to include("<nothing@example2.com>: Recipient address rejected: undeliverable address:")
      expect(last_bounce.email).to eql "nothing@example2.com"
    end

    it "raises for unusual bounces" do
      unusual_bounce = Mail.read_from_string(
        Rails.root.join("spec", "fixtures", "email", "list_bounce.eml")
        .read.gsub(/^.*nothing@example2.com.*$/, "")
      )
      allow(bounce_imap_mail).to receive(:mail).and_return(unusual_bounce)

      expect do
        bounce_handler.process
      end.to raise_error(MailingLists::BulkMail::NoBounceRecipientDetected)
        .with_message(/Mail seems to be a bounce, but the original recipient could not be detected./)
    end
  end
end
