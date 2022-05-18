# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Event::Participations
  class TableDisplayRow < Export::Tabular::People::TableDisplayRow

    attr_reader :participation

    def initialize(entry, table_display, format = nil)
      super(entry.person, table_display, format)
      @participation = entry
    end

    private

    def value_for(attr)
      column = table_display.column_for(attr)
      return super unless column.present?

      column.value_for(participation, attr) do |target, target_attr|
        if respond_to?(target_attr, true)
          send(target_attr)
        elsif target.respond_to?(target_attr)
          target.public_send(target_attr)
        end
      end
    end

  end
end
