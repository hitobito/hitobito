class MoreConsistentMailchimpCols < ActiveRecord::Migration[4.2]
  def change
    rename_column :mailing_lists, :syncing_mailchimp, :mailchimp_syncing
    rename_column :mailing_lists, :last_synced_mailchimp_at, :mailchimp_last_synced_at
  end
end
