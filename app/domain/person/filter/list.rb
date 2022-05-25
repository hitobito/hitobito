# frozen_string_literal: true

#  Copyright (c) 2017-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::List

  attr_reader :group, :user, :chain, :range, :name

  def initialize(group, user, params = {})
    @group = group
    @user = user
    @chain = Person::Filter::Chain.new(params[:filters])
    @range = params[:range]
    @name = params[:name]
    @ids = params[:ids].to_s.split(',')
  end

  def entries
    default_order(filtered_accessibles.preload_groups.distinct)
  end

  def all_count
    @all_count ||= filter.distinct.count
  end

  def multiple_groups
    range == 'deep' || range == 'layer'
  end

  private

  def filtered_accessibles
    accessibles.merge(filter_with_selection)
  end

  def filter_with_selection
    @ids.present? ? filter.where(id: @ids) : filter
  end

  def filter
    chain.present? ? chain.filter(list_range) : list_range.members
  end

  def list_range
    case range
    when 'deep'
      Person.in_or_below(group, chain.roles_join)
    when 'layer'
      Person.in_layer(group, join: chain.roles_join)
    else
      Person.in_group(group, chain.roles_join)
    end
  end

  def accessibles
    ability = accessibles_class.new(user, group_range? ? @group : nil, chain.roles_join)
    Person.accessible_by(ability)
  end

  def accessibles_class
    abilities = chain.required_abilities
    if abilities.include?(:full)
      PersonFullReadables
    else
      PersonReadables
    end
  end

  def group_range?
    !%w(deep layer).include?(range)
  end

  def default_order(entries)
    entries = entries.order_by_role if Settings.people.default_sort == 'role'
    entries.order_by_name
  end

end
