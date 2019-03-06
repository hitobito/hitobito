#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class TableDisplayParticipationRow < ParticipationRow
    attr_reader :table_display
    dynamic_attributes[/^event_question_\d+/] = :question_attribute

    def initialize(entry, table_display, format = nil)
      @table_display = table_display
      super(entry, format)
    end

    private

    def value_for(attr)
      table_display.with_permission_check(participation, attr) do
        super(attr.to_s.gsub('person.', ''))
      end
    end

  end

end
