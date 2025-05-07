# frozen_string_literal: true

#  Copyright (c) 2022-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::RegistrationClosedInfo
  extend ActiveSupport::Concern

  private

  def registration_closed? = !event.application_possible?

  def registration_closed_info
    if !event.application_period_open?
      I18n.t("event/register.application_window_closed")
    elsif !event.places_or_waiting_list_available?
      I18n.t("event/register.no_places_available")
    end
  end
end
