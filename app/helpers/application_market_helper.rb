# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module ApplicationMarketHelper
  def application_market_application_link(group, event, participation)
    link_to(icon("arrow-left"),
      "#",
      onclick: "event.preventDefault();
                $('#modal-placeholder').html('#{j render(partial: "modal_form",
                  locals: {group: group, event: event, participation: participation, method: :put})}');
                $('#application-confirmation').modal('show');")
  end

  def application_market_participant_link(group, event, participation)
    link_to(icon("arrow-right"),
      "#",
      onclick: "event.preventDefault();
                $('#modal-placeholder').html('#{j render(partial: "modal_form",
                  locals: {group: group, event: event, participation: participation, method: :delete})}');
                $('#application-confirmation').modal('show');")
  end
end
