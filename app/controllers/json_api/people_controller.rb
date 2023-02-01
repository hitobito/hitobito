# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApi::PeopleController < JsonApiController
  def index
    authorize!(:index_people, Group)
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

  private

  def entry
    @entry ||= Person.find(params[:id])
  end
end
