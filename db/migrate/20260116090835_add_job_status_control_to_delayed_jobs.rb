class AddJobStatusControlToDelayedJobs < ActiveRecord::Migration[8.0]
  def change
    add_column :delayed_jobs, :status_control, :string
  end
end
