class AddCustomSelfRegistrationTitleToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :group_translations, :custom_self_registration_title, :string
  end
end
