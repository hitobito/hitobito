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
    if filter.role_types.present?
      list_entries(kind).where(roles: { type: filter.role_types })
    else
      list_entries.members
    end
  end

  def list_entries(scope_kind = nil)
    apply_default_sort(list_scope(scope_kind).
                       preload_groups.
                       uniq)

  end

  def apply_default_sort(scope)
    scope = scope.order_by_role if Settings.people.default_sort == 'role'
    scope.order_by_name
  end

  def list_scope(scope_kind = nil)
    case scope_kind
    when 'deep'
      @multiple_groups = true
      accessibles.in_or_below(group)
    when 'layer'
      @multiple_groups = true
      accessibles.in_layer(group)
    else
      accessibles(group)
    end
  end

  def accessibles(group = nil)
    ability = PersonAccessibles.new(user, group)
    Person.accessible_by(ability)
  end

end
