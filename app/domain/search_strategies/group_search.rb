#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class GroupSearch < Base
    def search_fulltext
      return no_groups unless term_present?

      Group.search(@term).limit(@limit)
    end

    private

    def no_groups
      Group.none.page(1)
    end
  end
end
