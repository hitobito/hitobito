#  Copyright (c) 2021, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateEventInvitations < ActiveRecord::Migration[6.0]
  def change
    create_table :event_invitations do |t|
      t.string :participation_type, null: false
      t.datetime :declined_at
      t.timestamps

      t.belongs_to :event, null: false
      t.belongs_to :person, null: false

      t.index [:event_id, :person_id], unique: true
    end
  end
end
