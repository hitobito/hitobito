# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Base class for filter lists (people, events, etc.)
class Filter::List
  class_attribute :item_class, :filter_chain_class

  attr_reader :user, :params, :chain, :name

  def initialize(user, params = {})
    @user = user
    @params = params
    @chain = init_filter_chain(params[:filters])
    @name = params[:name]
    @ids = params[:ids].to_s.split(",")
  end

  def entries
    default_order(filtered_accessible_scope)
  end

  # the count of all filtered items, explicitly ignoring accessibility checks
  def all_count
    @all_count ||= filtered_scope.distinct.count
  end

  private

  def filtered_accessible_scope
    filtered = filtered_scope_with_selection.reselect(:id).distinct
    accessible_scope.where(id: filtered)
  end

  def filtered_scope_with_selection
    if @ids.present? && @ids != %w[all]
      filtered_scope.where(id: @ids)
    else
      filtered_scope
    end
  end

  def filtered_scope
    if chain.present?
      chain.filter(base_scope)
    else
      default_filter_scope
    end
  end

  def accessible_scope
    item_class.all
  end

  def base_scope
    item_class.all
  end

  # this scope is used if no filters are defined
  def default_filter_scope
    base_scope
  end

  def default_order(scope)
    scope.list
  end

  def init_filter_chain(filters)
    filter_chain_class.new(filters)
  end
end
