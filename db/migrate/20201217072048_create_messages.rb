# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class CreateMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :messages do |t|
      t.string :type, null: false
      t.integer :recipients_source_id
      t.string :recipients_source_type
      t.text :body
      t.string :subject
      t.timestamps
    end

    create_table :message_recipients do |t|
      t.belongs_to :person, null: false
      t.belongs_to :message, null: false
      t.string :status, null: false
      t.string :target
      t.timestamps
    end
  end
end
