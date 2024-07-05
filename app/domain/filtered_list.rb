# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# For each filtered subject-collection, you should create a dedicated subclass
# of this FilteredList-BaseClass
#
# Individual filters can be implemented as methods in the FilteredList-subclass
# or as their own filter-class. The applied filters are defined as Array in
# #filter_scopes Symbols are interpreted as instance-methods in the class,
# Class-Names are instantiated and called:
#
#   Subject::Filter::SpecificFilter.new(user, params, options, scope).to_scope
class FilteredList
  attr_reader :user, :params, :options

  def initialize(user, params = {}, options = {})
    @user = user
    @params = params
    @options = options
  end

  def entries
    @entries ||= fetch_entries.to_a
  end

  def fetch_entries
    chain_scopes(base_scope, *filter_scopes)
  end

  def to_scope
    fetch_entries
  end

  def empty?
    entries.blank?
  end

  # methods intended to be overridden

  def base_scope
    raise "Implement `base_scope` in your subclass."
  end

  def filter_scopes
    raise "Implement `filter_scopes` in your subclass"
  end

  private

  # purely internal methods

  def chain_scopes(scope, *filters)
    filters.reduce(scope) do |result, filter|
      case filter
      when Symbol then send(filter, result)
      when Class then filter.new(user, params, options, result).to_scope
      else raise "Filter type #{filter.inspect} not handled"
      end
    end
  end
end
