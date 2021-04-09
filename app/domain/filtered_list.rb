# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FilteredList
  attr_reader :params

  def initialize(user, params = {})
    @user = user
    @params = params
  end

  def entries
    @entries ||= fetch_entries.to_a
  end

  def fetch_entries
    chain_scopes(base_scope, :list, *filter_scopes)
  end

  def empty?
    entries.blank?
  end

  # methods intended to be overridden

  def base_scope
    raise 'Implement `base_scope` in your subclass.'
  end

  def filter_scopes
    raise 'Implement `filter_scopes` in your subclass'
  end

  private

  # purely internal methods

  def chain_scopes(scope, *filters)
    filters.reduce(scope) do |result, filter|
      case filter
      when Symbol then send(filter, result) || result
      when Class then filter.new(user, params, result).entries.presence || result
      else raise "Filter-Type #{filter.inspect} not handled"
      end
    end
  end

  def list(scope)
    scope.list # expectation that any filtered model has a list-scope
  end
end
