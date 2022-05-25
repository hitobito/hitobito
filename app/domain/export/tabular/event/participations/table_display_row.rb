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

    def column_entry
      participation
    end

  end
end
