# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ListsController < ApplicationController
  include YearBasedPaging
  include Events::EventListing

  skip_authorize_resource only: [:events, :courses]

  def events
    authorize!(:list_available, Event)

    @grouped_events = grouped(upcoming_user_events)
  end

  private

  def upcoming_user_events
    Event.
      upcoming.
      in_hierarchy(current_user).
      includes(:dates, :groups).
      where('events.type != ? OR events.type IS NULL', Event::Course.sti_name).
      order('event_dates.start_at ASC')
  end
end
