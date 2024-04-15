# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApi::Event::KindsController < JsonApiController
  def index
    authorize!(:index, Event::Kind)
    super
  end

  def show
    kind = Event::Kind.find(params[:id])
    authorize!(:show, kind)
    super
  end
end
