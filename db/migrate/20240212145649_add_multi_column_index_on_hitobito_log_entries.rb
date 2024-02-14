# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

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
