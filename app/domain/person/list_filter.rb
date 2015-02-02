# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::ListFilter

  attr_reader :group, :user, :kind, :filter, :multiple_groups

  def initialize(group, user, kind, role_type_ids)
    @group = group
    @user = user
    @kind = kind.to_s
    @filter = PeopleFilter.new(role_type_ids: role_type_ids)
  end

  def filter_entries
    entries = filtered_entries { |group| accessibles(group) }.preload_groups.uniq
    entries = entries.order_by_role if Settings.people.default_sort == 'role'
    entries.order_by_name
  end

  def all_count
    filtered_entries { |group| all(group) }.uniq.count
  end

  private

  def filtered_entries(&block)
    if filter.role_types.present?
      list_scope(kind, &block).where(roles: { type: filter.role_types })
    else
      block.call(group).members(group)
    end
  end

  def list_scope(scope_kind, &block)
    case scope_kind
    when 'deep'
      @multiple_groups = true
      block.call.in_or_below(group)
    when 'layer'
      @multiple_groups = true
      block.call.in_layer(group)
    else
      block.call(group)
    end
  end

  def all(group = nil)
    group ? group.people : Person
  end

  def accessibles(group = nil)
    ability = PersonAccessibles.new(user, group)
    Person.accessible_by(ability)
  end

end
