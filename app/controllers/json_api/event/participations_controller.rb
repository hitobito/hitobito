# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApi::Event::ParticipationsController < JsonApiController
  def index
    authorize!(:index, Event::Participation)
    super
  end

  def show
    participation = Event::Participation.find(params[:id])
    authorize!(:show, participation)
    super
  end
end
