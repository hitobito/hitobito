# frozen_string_literal: true

#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This migration can be deleted as soon as changes were applied
class RemoveAhvNumberFromRequiredContactAttrs < ActiveRecord::Migration[7.1]
  def up
    Event.where("required_contact_attrs LIKE '%ahv_number%'").find_each do |event|
      event.update!(required_contact_attrs: event.required_contact_attrs - ["ahv_number"])
    end

    Event.where("hidden_contact_attrs LIKE '%ahv_number%'").find_each do |event|
      event.update!(hidden_contact_attrs: event.hidden_contact_attrs - ["ahv_number"])
    end
  end

  def down
    # not needed
  end
end
