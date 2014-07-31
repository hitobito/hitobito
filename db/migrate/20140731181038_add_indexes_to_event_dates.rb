class AddIndexesToEventDates < ActiveRecord::Migration
  def change
    add_index(:event_dates, [:event_id, :start_at])
  end
end
