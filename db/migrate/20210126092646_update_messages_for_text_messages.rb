# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#
#  https://github.com/hitobito/hitobito

class UpdateMessagesForTextMessages < ActiveRecord::Migration[6.0]
  def up
    add_column :messages, :text, :text, limit: 1024
    add_column :message_recipients, :state, :string
    change_column :messages, :subject, :string, null: true, limit: 256
  end

  def down
    remove_column :messages, :text
    remove_column :message_recipients, :state
    change_column :messages, :subject, :string, null: false, limit: 256
  end
end
