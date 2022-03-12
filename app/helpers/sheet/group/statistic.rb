# frozen_string_literal: true

#  Copyright (c) 2022-2022, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Group
    class Statistic < Base
      self.parent_sheet = Sheet::Group

      def model_name
        'group'
      end
    end
  end
end
