# frozen_string_literal: true

class Events::FiltersController < ApplicationController
  before_action :authorize
  before_action :filter

  helper_method :filter, :group, :events_list_path, :filter_path

  def new
  end

  def create
    redirect_to result_path
  end

  private

  def filter
    @filter ||= Events::Filter::GroupList.new(group, current_user, params)
  end

  def result_path
    search_params = {}
    if filter.chain.present?
      search_params[:filters] = filter.chain.to_params
    end
    events_list_path(search_params)
  end

  def events_list_path(options = {})
    path = "#{filter.event_type.type_name}_group_events_path"
    options[:type] ||= filter.type
    options[:year] ||= filter.year
    options[:range] ||= filter.range || "deep"
    send(path, group, options)
  end

  def filter_path
    send(:"group_events_#{filter.event_type.type_name}_filters_path")
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize
    type = params[:type].presence || "Event"
    authorize!(:"index_#{type.underscore.pluralize}", group)
  end
end
