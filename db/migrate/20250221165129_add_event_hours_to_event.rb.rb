class AddEventHoursToEvent < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :event_hours, :string
  end
end
