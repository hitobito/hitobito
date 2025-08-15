# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module ApplicationMarketHelper
  def application_market_application_link(group, event, participation)
    link_to(icon("arrow-left"),
      "#",
      # rubocop:todo Layout/LineLength
      onclick: "event.preventDefault();
                $('#modal-placeholder').html('#{j render(partial: "shared/email_confirmation_modal",
                  locals: {method: :put,
                           modal_title: t(".modal_title"),
                           send_email_label: t(".confirm_and_send_mail"),
                           send_no_email_label: t(".confirm_and_send_no_mail"),
                           send_email_route: participant_group_event_application_market_path(group,
                             event, participation, send_email: true),
                           send_no_email_route: participant_group_event_application_market_path(
                             group, event, participation, send_email: false
                           )})}');
                $('#email-confirmation-modal').modal('show');")
    # rubocop:enable Layout/LineLength
  end

  def application_market_participant_link(group, event, participation)
    link_to(icon("arrow-right"),
      "#",
      # rubocop:todo Layout/LineLength
      onclick: "event.preventDefault();
                $('#modal-placeholder').html('#{j render(partial: "shared/email_confirmation_modal",
                  locals: {method: :delete,
                           modal_title: t(".modal_title"),
                           send_email_label: t(".confirm_and_send_mail"),
                           send_no_email_label: t(".confirm_and_send_no_mail"),
                           send_email_route: participant_group_event_application_market_path(group,
                             event, participation, send_email: true),
                           send_no_email_route: participant_group_event_application_market_path(
                             group, event, participation, send_email: false
                           )})}');
                $('#email-confirmation-modal').modal('show');")
    # rubocop:enable Layout/LineLength
  end
end
