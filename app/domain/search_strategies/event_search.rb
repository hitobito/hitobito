#  Copyright (c) 2012-2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class EventSearch < Base
    self.model_class = Event
    self.list_action = :list_available

    def search_fulltext
      super.includes(:groups, :dates)
    end

    def search_identifiers
      super.includes(:groups, :dates)
    end
  end
end
