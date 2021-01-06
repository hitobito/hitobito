# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateMailLog < ActiveRecord::Migration[6.0]

  def up
    change_table :mail_logs do |t|
      t.belongs_to :message
    end
    MailLog.reset_column_information
    subject_to_message
    remove_columns :mail_logs, :mailing_list_id, :mail_subject
  end

  def down
    add_column :mail_logs, :mail_subject, :string
    change_table :mail_logs do |t|
      t.belongs_to :mailing_list
    end
    MailLog.reset_column_information
    subject_to_mail_log
    remove_column :mail_logs, :message_id
  end

  private

  def subject_to_message
    MailLog.find_each do |l|
      message = Messages::BulkMail
        .create!(recipients_source_id: l.mailing_list_id,
                 recipients_source_type: MailingList.sti_name,
                 subject: l.mail_subject,
                 mail_log: l)
      l.update!(message: message)
    end
  end

  def subject_to_mail_log
    Message.where(type: [:messages_bulk_mail, :messages_mail]).find_each do |m|
      m.mail_log.update!(mail_subject: m.mail_subject, mailing_list_id: m.mailing_list_id)
    end
  end
end
