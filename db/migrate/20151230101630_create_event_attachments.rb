# encoding: utf-8

#  Copyright (c) 2015, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateEventAttachments < ActiveRecord::Migration[4.2]
  def change
    create_table :event_attachments do |t|
      t.belongs_to :event, null: false
      t.string :file, null: false
    end

    add_index :event_attachments, :event_id
  end
end
