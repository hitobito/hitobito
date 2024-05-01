# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddAutomaticAssignmentToEvents < ActiveRecord::Migration[6.1]
  def up
    add_column :events, :automatic_assignment, :boolean, null: false, default: false

    Event.where(type: event_types_using_priorization, priorization: false)
         .update_all(automatic_assignment: true)
  end

  def down
    remove_column :events, :automatic_assignment
  end

  private

  def event_types_using_priorization
    Event.all_types.select { |e| e.attr_used?(:priorization) }
      .map(&:sti_name)
  end
end
