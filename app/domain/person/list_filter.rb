# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::ListFilter

  class_attribute :accessibles_class
  self.accessibles_class = PersonReadables

  attr_reader :group, :user, :multiple_groups

  def initialize(group, user)
    @group = group
    @user = user
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

  def unfiltered_entries(&block)
    block.call(group).members(group)
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
    ability = accessibles_class.new(user, group)
    Person.accessible_by(ability)
  end

end