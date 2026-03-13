# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilteredEvents
  extend ActiveSupport::Concern
  include ParamConverters # for list_param

  private

  def all_filtered_or_listed_events
    if params[:ids] == "all"
      params.delete(:ids)

      @event_ids = %w[all]
      event_filter.entries
    else
      Event.where(id: list_param(:ids)).distinct
    end
  end

  def event_filter
    @event_filter = Events::Filter::List.new(
      group, current_user, params
    )
  end
end
