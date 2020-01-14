class IndexEventApplicationInEventParticipation < ActiveRecord::Migration[4.2]
  def change
    add_index(:event_participations, :application_id)
  end
end
