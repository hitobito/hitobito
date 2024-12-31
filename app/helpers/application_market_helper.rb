# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module ApplicationMarketHelper
  def application_market_application_link(group, event, participation)
    link_to(icon("arrow-left"),
      participant_group_event_application_market_path(group, event, participation),
      remote: true,
      method: :put)
  end

  def application_market_participant_link(group, event, participation)
    link_to(icon("arrow-right"),
      participant_group_event_application_market_path(group, event, participation),
      remote: true,
      method: :delete)
  end
end
