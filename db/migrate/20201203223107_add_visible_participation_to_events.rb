class AddVisibleParticipationToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :participations_visible, :boolean, null: false, default: false
  end
end
