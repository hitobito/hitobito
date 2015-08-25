class AddRepresentativeEventParticipantCount < ActiveRecord::Migration
  def change
    add_column :events, :representative_participant_count, :integer, default: 0
  end
end
