#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddSensitiveToEventQuestion < ActiveRecord::Migration[8.0]
  def change
    add_column :event_questions, :sensitive, :boolean, null: false, default: true
  end
end
