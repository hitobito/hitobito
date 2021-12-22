class AddNotifyContactOnParticipationsToEvent < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :notify_contact_on_participations, :boolean, default: false, null: false
  end
end
