# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class MigrateMailLog < ActiveRecord::Migration[6.0]

  def up
    change_table :mail_logs do |t|
      t.belongs_to :message
    end
    subject_to_message
    remove_column :mail_logs, :mailing_list_id
  end

  def down
    subject_to_mail_log
    change_table :mail_logs do |t|
      t.belongs_to :mailing_list
    end
    remove_column :mail_logs, :message_id
  end

  private

  def subject_to_message
    MailLog.find_each do |l|
      message = Messages::BulkMail
        .create!(mailing_list_id: l.mailing_list_id,
                 subject: l.mail_subject,
                 mail_log: l)
      l.update!(message: message, mail_subject: nil)
    end
  end

  def subject_to_mail_log
    Message.where(type: [:messages_bulk_mail, :messages_mail]).find_each do |m|
      m.mail_log.update!(mail_subject: m.mail_subject, mailing_list_id: m.mailing_list_id)
    end
  end
end
