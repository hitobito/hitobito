#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddParticipationsFilter < ActiveRecord::Migration[8.0]
  def change
    create_table :event_participations_filters do |t|
      t.belongs_to :event
      t.string :participant_type
    end
  end
end
