class MoreConsistentMailchimpCols < ActiveRecord::Migration
  def change
    rename_column :mailing_lists, :syncing_mailchimp, :mailchimp_syncing
    rename_column :mailing_lists, :last_synced_mailchimp_at, :mailchimp_last_synced_at

    if column_exists?(:mailing_lists, :sync_mailchimp_automatically)
      remove_column :mailing_lists, :sync_mailchimp_automatically
    end
  end
end
