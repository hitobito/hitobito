class AddMailchimpAttributesToMailingList < ActiveRecord::Migration[4.2]
  def change
    add_column :mailing_lists, :mailchimp_api_key, :string
    add_column :mailing_lists, :mailchimp_list_id, :string
    add_column :mailing_lists, :syncing_mailchimp, :boolean, default: false
    add_column :mailing_lists, :last_synced_mailchimp_at, :datetime
  end
end
