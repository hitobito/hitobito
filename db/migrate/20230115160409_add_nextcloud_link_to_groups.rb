class AddNextcloudLinkToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :nextcloud_url, :string
  end
end
