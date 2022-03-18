#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays
  class MultiColumn < Column

    class << self
      def can_display?(attr)
        raise 'implement in subclass'
      end

      def available(list)
        raise 'implement in subclass'
      end
    end

  end
end
