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

    create_bulk_mail_messages
    assign_mail_logs_message_id

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

    to_mail_log

    remove_column :mail_logs, :message_id
  end

  private

  def create_bulk_mail_messages
    MailLog.find_in_batches do |logs|
      message_rows = []
      logs.each do |log|
        message_rows << message_attrs(log)
      end
      Message.insert_all!(message_rows)
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
