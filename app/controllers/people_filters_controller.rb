# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeopleFiltersController < CrudController

  self.nesting = Group

  decorates :group

  hide_action :index, :show, :edit, :update

  skip_authorize_resource only: :create

  # load group before authorization
  prepend_before_filter :parent

  before_render_form :compose_role_lists

  def create
    if params[:button] == 'save'
      authorize!(:create, entry)
      super(location: group_people_path(group, model_params.merge(kind: :deep)))
    else
      authorize!(:new, entry)
      types = (model_params && model_params[:role_types]) || {}
      redirect_to group_people_path(group, role_types: types, kind: :deep)
    end
  end

  def destroy
    super(location: group_people_path(group))
  end

  private

  alias_method :group, :parent

  def build_entry
    filter = super
    filter.group_id = group.id
    filter
  end

  def compose_role_lists
    @role_types = Role::TypeList.new(group.layer_group.class)
  end
end