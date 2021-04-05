# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Events::Filter::List

  # needed or just class-internal laziness?
  # attr_reader :group, :user, :chain, :range, :name, :multiple_groups

  def initialize(group, user, params = {})
    @group = group
    @user = user
    @chain = Events::Filter::Chain.new(params[:filters])
    @range = params[:range]
    @name = params[:name]
    @ids = params[:ids].to_s.split(',')
  end

  # unchanged
  def entries
    default_order(filtered_accessibles.preload_groups.distinct)
  end

  # unchanged
  def all_count
    @all_count ||= filter.distinct.count
  end

  private

  # unchanged
  def filtered_accessibles
    return filter unless user

    if group_range?
      filtered = filter.unscope(:select).select(:id).distinct
      filtered = filtered.where(id: @ids) if @ids.present?
      accessibles.unscope(:select).where(id: filtered)
    else
      accessibles.merge(filter)
    end
  end

  # unchanged
  def filter
    chain.present? ? chain.filter(list_range) : list_range
  end

  # needs change
  def accessibles
    ability = accessibles_class.new(user, group_range? ? @group : nil, chain.roles_join)

    Event.accessible_by(ability) # action defaults to :index
  end

  # needs change, may be obsolete
  def accessibles_class
    EventAbility
    # abilities = chain.required_abilities
    # if abilities.include?(:full)
    #   PersonFullReadables
    # else
    #   PersonReadables
    # end
  end

  # needs change
  def list_range
    raise 'Yo, ICANHAZ Implementation PLZ'
    # case range
    # when 'deep'
    #   @multiple_groups = true
    #   Person.in_or_below(group, chain.roles_join)
    # when 'layer'
    #   @multiple_groups = true
    #   Person.in_layer(group, join: chain.roles_join)
    # else
    #   group_scope = Person.in_group(group, chain.roles_join)
    #   chain.blank? ? group_scope.members(group) : group_scope
    # end
  end

  # unchanged
  def group_range?
    !%w(deep layer).include?(range)
  end

  # needs change
  def default_order(entries)
    entries = entries.order_by_role if Settings.people.default_sort == 'role'
    entries.order_by_name
  end
end
