# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  module TextMessageProvider
    class Base

      def initialize(config:)
        @config = config
      end

      def send(text, recipients)
        raise 'implement in subclass'
      end
    end
  end
end
