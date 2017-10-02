class AddEventDisplayBookingInfoFlag < ActiveRecord::Migration
  def change
    add_column :events, :display_booking_info, :boolean, null: false, default: true
  end
end
