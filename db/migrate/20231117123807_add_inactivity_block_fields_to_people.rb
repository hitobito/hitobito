# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddInactivityBlockFieldsToPeople < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :inactivity_block_warning_sent_at, :datetime, null: true
    add_column :people, :blocked_at, :datetime, null: true
  end
end
