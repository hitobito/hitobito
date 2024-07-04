#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class Group::ListsController < ApplicationController
  def index
    authorize!(:index, Group)

    respond_to do |format|
      format.json do
        render json: ListSerializer.new(groups, serializer: GroupListSerializer, controller: self)
      end
    end
  end

  private

  def groups
    @groups ||= Group.all
  end
end
