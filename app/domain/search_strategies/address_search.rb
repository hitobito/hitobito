#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class AddressSearch < Base
    def search_fulltext
      return no_adresses unless term_present?

      Address.search(@term)
    end

    private

    def no_adresses
      Address.none.page(1)
    end
  end
end
