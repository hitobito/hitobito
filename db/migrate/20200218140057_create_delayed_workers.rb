class CreateDelayedWorkers < ActiveRecord::Migration[6.0]

  def change
    create_table(:delayed_workers) do |t|
      t.string :name
      t.string :version
      t.datetime :last_heartbeat_at
      t.string :host_name
      t.string :label
    end
  end

end
