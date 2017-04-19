class AddCancelParticipationEnabledToEvent < ActiveRecord::Migration
  def change
    add_column :events, :applications_cancelable, :boolean, default: false, null: false
  end
end
