class RegenerateEventParticipantCounts < ActiveRecord::Migration
  def up
    # Recalculate the counts of all events as teamers got omitted in certain cases
    Event.find_each { |e| e.refresh_participant_counts! }
  end

  def down
  end
end
