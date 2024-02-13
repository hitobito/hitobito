class AddMultiColumnIndexOnHitobitoLogEntries < ActiveRecord::Migration[6.1]
  def change
    add_index :hitobito_log_entries,
              [:category, :level, :subject_id, :subject_type, :message],
              length: { message: 255 },
              name: 'index_hitobito_log_entries_on_multiple_columns'

    # to look up category the multi column index can be used as well, so we do not
    # need a separate index for category
    remove_index :hitobito_log_entries, :category
  end
end
