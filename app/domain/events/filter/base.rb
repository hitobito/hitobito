# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Events::Filter::Base < Filter::Base
  attr_reader :event_type

  def initialize(attr, args, event_type = nil)
    super(attr, args)
    @event_type = event_type
  end

  private

  def event_types
    event_type ? [event_type] : [Event] + Event.subclasses
  end
end
