# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.
#
# Fetches people for which the user has write access via layer permissions.
class PersonLayerWritables < PersonFetchables

  self.same_group_permissions = []
  self.above_group_permissions = []
  self.same_layer_permissions = [:layer_and_below_full, :layer_full]
  self.above_layer_permissions = [:layer_and_below_full]

  def initialize(user)
    super(user)

    can :index, Person, accessible_people { |_| true }
  end

  private

  def accessible_people
    if user.root?
      Person.only_public_data
    else
      accessible_people_scope
    end
  end

  def accessible_people_scope
    conditions = writable_conditions
    if conditions.present?
      Person.only_public_data.
        joins(roles: :group).
        where(roles: { deleted_at: nil }, groups: { deleted_at: nil }).
        where(conditions.to_a).
        distinct
    else
      Person.none
    end
  end

  def writable_conditions
    OrCondition.new.tap do |condition|
      append_group_conditions(condition)
    end
  end

end
