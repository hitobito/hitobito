class IndexEventApplicationInEventParticipation < ActiveRecord::Migration
  def change
    add_index(:event_participations, :application_id)
  end
end
