# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Events::Filter::Chain < Filter::Chain
  self.types = [
    Events::Filter::DateRange,
    Events::Filter::State,
    Events::Filter::PlacesAvailable,
    Events::Filter::Groups,
    Events::Filter::CourseKind,
    Events::Filter::CourseKindCategory,
    Events::Filter::FullText,
    Events::Filter::Leader,
    Events::Filter::Attributes
  ]

  attr_reader :event_type

  def initialize(event_type, params = nil)
    @event_type = event_type
    super(params)
  end

  def init_filter(type, attr, args)
    type.new(attr, args, event_type)
  end
end
