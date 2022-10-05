# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
migration_file_name = Dir[Rails.root.join('db/migrate/20210212111156_migrate_mail_log.rb')].first
require migration_file_name


describe MigrateMailLog do

  before(:all) { self.use_transactional_tests = false }
  after(:all)  { self.use_transactional_tests = true }

  let(:migration) { described_class.new.tap { |m| m.verbose = false } }
  let(:mailing_list) { mailing_lists(:leaders) }

  let(:mail_log_entries) do
    10.times.collect do
      MailLog.create!(
        mail_from: Faker::Internet.email,
        mail_hash: Digest::MD5.new.hexdigest(Faker::Lorem.characters(number: 200)),
        status: MailLog.statuses.to_a.sample.first,
        updated_at: Faker::Time.between(from: DateTime.now - 3.months, to: DateTime.now)
      )
    end
  end

  let(:bulk_mails) do
    mail_log_entries.collect do |log|
      Message::BulkMail.create!(
        subject: Faker::Book.genre,
        mail_log: log
      )
    end
  end

  before do
    MailLog.delete_all
    Message.delete_all
  end

  after do
    MailLog.delete_all
    Message.delete_all
  end

  context '#up' do
    let(:legacy_mail_logs) do
      10.times.collect do
        MailLog.create!(
          mailing_list_id: mailing_list.id,
          mail_subject: Faker::Book.title,
          mail_from: Faker::Internet.email,
          mail_hash: Digest::MD5.new.hexdigest(Faker::Lorem.characters(number: 200)),
          status: MailLog.statuses.to_a.sample.first,
          updated_at: Faker::Time.between(from: DateTime.now - 3.months, to: DateTime.now)
        )
      end
    end

    before do
      migration.down
      legacy_mail_logs
    end

    it 'creates messages/bulk_mail for every log entry' do
      expect do
        migration.up
      end.to change { Message::BulkMail.count }.by(10)
        .and change(MailLog, :count).by(0)

      legacy_mail_logs.each do |l|
        message_state = MailLog::BULK_MESSAGE_STATUS[l.status.to_sym]
        expect(Message::BulkMail.where(
          subject: l.mail_subject,
          sent_at: l.updated_at,
          mailing_list_id: l.mailing_list_id,
          state: message_state)).to exist
      end

      Message::BulkMail.all.each do |m|
        expect(MailLog.where(message_id: m.id)).to exist
      end
    end
  end

  context '#down' do
    after do
      migration.up
    end

    it 'updates log subject and mailing list according to bulk mail' do
      mails = bulk_mails.map { |m| { subject: m.subject, mailing_list_id: m.mailing_list_id } }
      expect do
        migration.down
      end.to change { Message.count }.by(-10)
        .and change(MailLog, :count).by(0)

      mails.each do |mail|
        expect(MailLog.where(mail_subject: mail[:subject])).to exist
        expect(MailLog.where(mailing_list_id: mail[:mailing_list_id])).to exist
      end
    end
  end

end
