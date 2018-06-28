class AddMailchimpAttributesToMailingList < ActiveRecord::Migration
  def change
    add_column :mailing_lists, :mailchimp_api_key, :string
    add_column :mailing_lists, :mailchimp_list_id, :string
    add_column :mailing_lists, :syncing_mailchimp, :boolean, default: false
    add_column :mailing_lists, :sync_mailchimp_automatically, :boolean, default: false
  end
end
