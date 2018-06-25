class AddMailchimpAttributesToGroup < ActiveRecord::Migration
  def change
    add_column :groups, :mailchimp_api_key, :string
    add_column :groups, :mailchimp_list_id, :string
  end
end
