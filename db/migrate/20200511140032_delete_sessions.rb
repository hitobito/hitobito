class DeleteSessions < ActiveRecord::Migration[6.0]
  def change
    execute "DELETE FROM sessions"
  end
end
