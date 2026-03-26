# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class Attributes < Base
    include Filter::Attributes

    self.model_class = Event

    def initialize(attr, args, event_type)
      @attr = attr
      @args = args
      @event_type = event_type
    end

    private

    def model_class
      event_type
    end
  end
end
