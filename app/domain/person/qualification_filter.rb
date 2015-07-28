# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::QualificationFilter

  attr_reader :group, :user, :kind, :validity, :qualification_kind_ids, :multiple_groups

  def initialize(group, user, params)
    @group = group
    @user = user
    @kind = params[:kind].to_s
    @validity = params[:validity].to_s
    @qualification_kind_ids = params[:qualification_kind_id]
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
    if qualification_kind_ids.present?
      entries_with_qualifications(list_scope(kind, &block))
    else
      block.call(group).members(group)
    end
  end

  def entries_with_qualifications(scope)
    scope = scope.joins(:qualifications).
                  where(qualifications: { qualification_kind_id: qualification_kind_ids })

    case validity
    when 'active' then scope.merge(Qualification.active)
    when 'reactivateable' then scope.merge(Qualification.reactivateable)
    else scope
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
    ability = PersonFullReadables.new(user, group)
    Person.accessible_by(ability)
  end

end
