# encoding: utf-8

#  Copyright (c) 2015, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RegenerateEventParticipantCounts < ActiveRecord::Migration[4.2]
  def up
    # Recalculate the counts of all events as teamers got omitted in certain cases
    Event.find_each { |e| e.refresh_participant_counts! }
  end

  def down
  end
end
