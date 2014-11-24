# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeopleFiltersController < CrudController

  self.nesting = Group

  self.permitted_attrs = [:name, :role_type_ids, role_types: [], role_type_ids: []]

  decorates :group

  hide_action :index, :show, :edit, :update

  skip_authorize_resource only: :create

  # load group before authorization
  prepend_before_action :parent

  before_render_form :compose_role_lists

  def create
    if params[:button] == 'save'
      authorize!(:create, entry)
      super(location: result_path)
    else
      authorize!(:new, entry)
      redirect_to result_path
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

  def result_path
    assign_attributes
    params = {}
    if entry.role_types.present?
      params = { name: entry.name, role_type_ids: entry.role_type_ids_string, kind: :deep }
    end
    group_people_path(group, params)
  end

  def compose_role_lists
    @role_types = Role::TypeList.new(group.class)
  end

  def permitted_params
    model_params ? model_params.permit(permitted_attrs) : {}
  end
end
