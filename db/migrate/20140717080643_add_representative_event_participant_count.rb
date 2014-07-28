class AddRepresentativeEventParticipantCount < ActiveRecord::Migration
  def change
    add_column :events, :representative_participant_count, :integer, default: 0

    # Calculate the counts of all events
    Event.all.each { |e| e.refresh_representative_participant_count! }
  end
end
