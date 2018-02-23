# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::List

  attr_reader :group, :user, :chain, :range, :name, :multiple_groups

  def initialize(group, user, params = {})
    @group = group
    @user = user
    @chain = Person::Filter::Chain.new(params[:filters])
    @range = params[:range]
    @name = params[:name]
  end

  def entries
    default_order(filtered.preload_groups)
  end

  def filtered
    filter(accessibles)
  end

  def all_count
    @all_count ||= filter(all).count
  end

  private

  def filter(scope)
    if chain.present?
      chain.filter(list_range(scope)).uniq
    else
      scope.members(group).uniq
    end
  end

  def accessibles
    ability = accessibles_class.new(user, group_range? ? group : nil)
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

  def all
    chain.blank? || group_range? ? group.people : Person
  end

  def list_range(scope)
    case range
    when 'deep'
      @multiple_groups = true
      scope.in_or_below(group)
    when 'layer'
      @multiple_groups = true
      scope.in_layer(group)
    else
      scope.to_sql['INNER JOIN `roles`'] ? scope : scope.joins(:roles)
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
