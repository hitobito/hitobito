# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
migration_file_name = Dir[Rails.root.join('db/migrate/20201218104956_migrate_mail_log.rb')].first
require migration_file_name


describe MigrateMailLog do

  before(:all) { self.use_transactional_tests = false }
  after(:all)  { self.use_transactional_tests = true }

  let(:migration) { described_class.new }
  let(:mailing_list) { mailing_lists(:leaders) }

  let(:legacy_mail_logs) do
    10.times.collect do
      MailLog.create!(
        mailing_list_id: mailing_list.id,
        mail_subject: Faker::Book.title,
        mail_from: Faker::Internet.email,
        mail_hash: Digest::MD5.new.hexdigest(Faker::Lorem.characters(200)),
        status: MailLog.statuses.to_a.sample.first,
        updated_at: Faker::Time.between(DateTime.now - 3.months, DateTime.now) 
      )
    end
  end

  context '#up' do

    before do
      migration.down
      legacy_mail_logs
    end

    it 'creates messages/bulk_mail for every log entry' do
      expect do
        migration.up
      end.to change { Messages::BulkMail.count }.by(10)

      legacy_mail_logs.each do |l|
        expect(Messages::BulkMail.where(
          recipients_source_id: mailing_list.id,
          recipients_source_type: MailingList.sti_name,
          subject: l.mail_subject)
        ).to exist
      end

      Messages::BulkMail.all.each do |m|
        expect(MailLog.where(message_id: m.id)).to exist
      end
    end
  end

end
