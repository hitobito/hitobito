#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MakeParticipationPersonPolymorphic < ActiveRecord::Migration[7.1]
  def change
    rename_column :event_participations, :person_id, :participant_id

    add_column :event_participations, :participant_type, :string
    add_index :event_participations, [:participant_type, :participant_id]
    add_index :event_participations, [:participant_type, :participant_id, :event_id], unique: true, name: "index_event_participations_on_polymorphic_and_event"

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE event_participations
          SET participant_type = 'Person'
        SQL
      end
    end
  end
end
