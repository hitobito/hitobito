class AddEventDisplayBookingInfoFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :display_booking_info, :boolean, null: false, default: true
  end
end
