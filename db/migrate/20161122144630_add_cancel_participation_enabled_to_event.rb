class AddCancelParticipationEnabledToEvent < ActiveRecord::Migration
  def change
    add_column :events, :cancel_participation_enabled, :boolean, default: false
  end
end
