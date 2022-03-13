# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Calendars::FeedsController < ApplicationController

  def index
    respond_to do |format|
      format.ics do
        calendar = nil
        if params[:calendar_token].present?
          calendar = Calendar.find_by(id: params[:calendar_id], token: params[:calendar_token])
        end
        return head :not_found unless calendar
        events = Calendars::Events.new(calendar).events
        send_data Export::Ics::Events.new.generate(events), type: :ics, disposition: :inline
      end
    end
  end

  private

  def devise_controller?
    request.format.ics? # hence, no login required
  end

end
