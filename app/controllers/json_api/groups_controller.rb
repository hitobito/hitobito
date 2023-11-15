# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class JsonApi::GroupsController < JsonApiController
  def index
    authorize!(:index, Group)
    resources = resource_class.all(params)
    render(jsonapi: resources)
  end

  def show
    group = Group.find(params[:id])
    authorize!(:show, group)
    super
  end
end
