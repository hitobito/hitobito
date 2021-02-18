# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateMailLog < ActiveRecord::Migration[6.0]

  def up
    change_table(:mail_logs) { |t| t.belongs_to :message }

    # temporarly add mail log id for migration
    add_column :messages, :mail_log_id, :bigint
    MailLog.reset_column_information
    Message.reset_column_information

    say_with_time 'creating bulk mail messages' do
      create_bulk_mail_messages
    end

    say_with_time 'linking mail-logs to messages' do
      assign_mail_logs_message_id
    end

    remove_columns :mail_logs, :mailing_list_id, :mail_subject
    remove_columns :messages, :mail_log_id
    Message.reset_column_information
  end

  def down
    add_column :mail_logs, :mail_subject, :string
    change_table :mail_logs do |t|
      t.belongs_to :mailing_list
    end
    MailLog.reset_column_information

    say_with_time 'extract mail-logs from messages' do
      to_mail_log
    end

    remove_column :mail_logs, :message_id
  end

  private

  def create_bulk_mail_messages
    MailLog.find_in_batches do |logs|
      message_rows = logs.map { |log| message_attrs(log) }
      create_messages(message_rows)
    end
  end

  def create_messages(message_rows)
    Message.insert_all!(message_rows)
  rescue => e
    if (row = e.message.scan(/.*row (\d+)$/).flatten.first)
      msg = message_rows.delete_at(row.to_i - 1)
      say "Error creating Message", :subitem
      puts e.message
      puts msg.inspect
      say "skipping it and retrying the insert", :subitem
      retry
    end
  end

  def message_attrs(log)
    now = Time.zone.now
    message_status = MailLog::BULK_MESSAGE_STATUS[log.status.to_sym]
    { subject: log.mail_subject,
      state: message_status,
      mail_log_id: log.id,
      type: Message::BulkMail.sti_name,
      created_at: now,
      updated_at: now,
      sent_at: log.updated_at,
      mailing_list_id: log.mailing_list_id }
  end

  def assign_mail_logs_message_id
    Message::BulkMail.find_in_batches do |msgs|
      now = Time.zone.now
      # created_at, updated_at has to be set since upsert_all
      # is complaining about missing default values

      log_rows = msgs.map do |m|
        { id: m.mail_log_id, message_id: m.id, created_at: now, updated_at: now }
      end
      MailLog.upsert_all(log_rows)
    end
  end

  def to_mail_log
    Message::BulkMail.includes(:mail_log).find_in_batches do |msgs|
      now = Time.zone.now
      # created_at, updated_at has to be set since upsert_all
      # is complaining about missing default values

      log_rows = msgs.map do |m|
        { id: m.mail_log.id, mail_subject: m.subject,
          mailing_list_id: m.mailing_list_id,
          created_at: now, updated_at: now }
      end
      MailLog.upsert_all(log_rows)
    end
    Message::BulkMail.destroy_all
  end
end
