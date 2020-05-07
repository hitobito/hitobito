# encoding: utf-8

#  Copyright (c) 2012-2014, insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ModifyEventCounts < ActiveRecord::Migration[4.2]
  def change
    rename_column :events, :representative_participant_count, :applicant_count
    add_column :events, :teamer_count, :integer, default: 0

    # Recalculate the counts of all events
    Event.find_each { |e| e.refresh_participant_counts! }
  end
end
