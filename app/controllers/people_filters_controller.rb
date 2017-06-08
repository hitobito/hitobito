# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeopleFiltersController < CrudController

  self.nesting = Group

  decorates :group

  hide_action :index, :show

  skip_authorize_resource only: [:create]

  # load group before authorization
  prepend_before_action :parent

  before_render_form :compose_role_lists

  helper_method :people_list_path

  def new
    assign_attributes
    super
  end

  def create
    if params[:button] == 'save'
      authorize!(:create, entry)
      super
    else
      authorize!(:new, entry)
      assign_attributes
      redirect_to result_path
    end
  end

  def destroy
    super(location: people_list_path)
  end

  private

  alias group parent

  def build_entry
    filter = super
    filter.group_id = group.id
    filter
  end

  def return_path
    super || people_list_path(filter_id: entry.id)
  end

  def result_path
    search_params = {}
    if entry.filter_chain.present?
      search_params = {
        name: entry.name,
        range: entry.range || 'deep',
        filters: entry.filter_chain.to_params
      }
    end
    people_list_path(search_params)
  end

  def compose_role_lists
    @role_types = Role::TypeList.new(group.class)
    @qualification_kinds = QualificationKind.list.without_deleted
  end

  def assign_attributes
    entry.name = params[:name] || (params[:people_filter] && params[:people_filter][:name])
    entry.range = params[:range]
    entry.filter_chain = params[:filters]
  end

  def people_list_path(options = {})
    group_people_path(group, options)
  end

end
