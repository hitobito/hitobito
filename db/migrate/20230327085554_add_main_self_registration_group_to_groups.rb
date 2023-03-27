class AddMainSelfRegistrationGroupToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :main_self_registration_group, :boolean, null: false, default: false
  end
end
