# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApi::EventsController < JsonApiController
  def index
    authorize!(:list_available, Event)
    super
  end

  def show
    event = Event.find(params[:id])
    authorize!(:show, event)
    super
  end
end
