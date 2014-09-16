class AddRepresentativeEventParticipantCount < ActiveRecord::Migration
  def change
    add_column :events, :representative_participant_count, :integer, default: 0

    # Calculate the counts of all events
    Event.find_each { |e| e.refresh_participant_counts! }
  end
end
