# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and
#  licensed under the Affero General Public License version 3 or later. See the
#  COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApi::RolesController < JsonApiController
  def index
    authorize!(*index_authorization_args)
    super
  end

  def show
    authorize!(:show, entry)
    super
  end

  def update
    authorize!(:update, entry)
    super
  end

  def destroy
    authorize!(:destroy, entry)
    super
  end

  private

  def entry
    @entry ||= Role.find(params[:id])
  end

  def index_authorization_args
    case current_ability
    when TokenAbility then [:index, Role]
    else [:index_people, Group]
    end
  end
end
