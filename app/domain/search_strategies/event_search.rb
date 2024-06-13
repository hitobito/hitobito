#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class EventSearch < Base
    def search_fulltext
      return no_events unless term_present?

      Event.search(@term).includes(:groups, :dates)
    end   

    private

    def no_events
      Event.none.page(1)
    end
  end
end