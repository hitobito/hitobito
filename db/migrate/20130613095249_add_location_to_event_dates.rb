class AddLocationToEventDates < ActiveRecord::Migration
  def change
    add_column(:event_dates, :location, :string)
  end
end
