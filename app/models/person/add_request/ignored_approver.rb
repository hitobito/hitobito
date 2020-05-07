# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: person_add_request_ignored_approvers
#
#  id        :integer          not null, primary key
#  group_id  :integer          not null
#  person_id :integer          not null
#
class Person::AddRequest::IgnoredApprover < ActiveRecord::Base

  belongs_to :group, class_name: '::Group'
  belongs_to :person

  validates_by_schema
  validates :person_id, uniqueness: { scope: :group_id }

  class << self

    def approvers(layer)
      ignored = select(:person_id).where(group_id: layer.id)
      possible_approvers(layer).where.not(people: { id: ignored })
    end

    def possible_approvers(layer)
      Person.in_layer(layer).
        where(roles: { type: approver_role_types.collect(&:sti_name) }).
        distinct
    end

    def approver_role_types
      Role.all_types.select do |type|
        (type.permissions & [:layer_full, :layer_and_below_full]).present?
      end
    end

    def delete_old_ones
      Group.where(id: distinct.pluck(:group_id)).find_each do |group|
        where(group_id: group.id).
        where.not(person_id: possible_approvers(group)).
        destroy_all
      end
    end

  end

end
