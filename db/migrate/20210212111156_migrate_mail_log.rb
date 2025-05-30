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

    remove_columns :mail_logs, :mailing_list_id, :mail_subject
    remove_columns :messages, :mail_log_id
  end

  def down
    add_column :mail_logs, :mail_subject, :string
    change_table :mail_logs do |t|
      t.belongs_to :mailing_list
    end

    remove_column :mail_logs, :message_id
  end

end
