#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class PolymorphicShowFullColumn < PolymorphicPublicColumn
    def required_permission(_attr)
      :show_full
    end
  end
end
