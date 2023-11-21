#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddMinimizedAtToPeople < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :minimized_at, :timestamp, null: true
  end
end
