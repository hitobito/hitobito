# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangeEventContactAttrMappings < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up { execute update_events('address', 'street') }
      dir.down { execute update_events('street', 'address') }
    end
  end

  private

  def update_events(from, to)
    <<~SQL.squish
      UPDATE
        events
      SET
        required_contact_attrs = REPLACE(required_contact_attrs, '- #{from}', '- #{to}'),
        hidden_contact_attrs = REPLACE(hidden_contact_attrs, '- #{from}', '- #{to}')
    SQL
  end
end
