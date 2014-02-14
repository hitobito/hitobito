class AddQualifiedToParticipation < ActiveRecord::Migration

  def up
    add_column :event_participations, :qualified, :boolean
  end

  def down
    remove_column :event_participations, :qualified
  end

end
