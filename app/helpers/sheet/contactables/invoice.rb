#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  module Contactables
    class Invoice < Base
      class << self
        def parent_sheet_for(view_context)
          view_context.parent.is_a?(::Person) ? Sheet::Person : Sheet::Group
        end
      end
    end
  end
end
