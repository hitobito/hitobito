class AddExternalApplicationsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :external_applications, :boolean, :default => false
  end
end
