# frozen_string_literal: true

#  Copyright (c) 2017-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::List < Filter::List
  self.item_class = Person
  self.filter_chain_class = Person::Filter::Chain

  attr_reader :group, :range

  def initialize(group, user, params = {}, list_action = nil)
    super(user, params)
    @group = group
    @range = params[:range]
    @list_action = list_action
  end

  def entries
    super.preload_groups.distinct
  end

  def multiple_groups
    range == "deep" || range == "layer"
  end

  private

  def accessible_scope
    people = Person.only_public_data.select(:contact_data_visible)
    people = people.in_group(@group, group_roles_join) if group_range?
    return people if all_group_people_accessible?

    people.accessible_by(ability, list_action)
  end

  def group_roles_join
    chain.include_ended_roles? ? {roles_with_ended_readable: :group} : {roles: :group}
  end

  def all_group_people_accessible?
    group_range? && list_action != :show_full && ability.can?(:index_local_people, @group)
  end

  def default_order(people)
    people = people.order_by_role if Settings.people.default_sort == "role"
    people.order_by_name
  end

  def default_filter_scope
    # When not filtering, the default is to exclude all passive and external people,
    # i.e. include only members
    base_scope.where(roles: {archived_at: nil})
      .or(base_scope.where(Role.arel_table[:archived_at].gt(Time.now.utc)))
      .members
  end

  def list_action
    @list_action ||=
      if full_ability_needed? then :show_full
      elsif chain.include_ended_roles? then :index_with_ended_roles
      else
        :index
      end
  end

  def ability
    @ability ||= Ability.new(user)
  end

  def full_ability_needed?
    chain.required_abilities.include?(:full)
  end

  def group_range?
    !%w[deep layer].include?(range)
  end

  def base_scope
    case range
    when "deep"
      Person.in_or_below(group, chain.roles_join)
    when "layer"
      Person.in_layer(group, join: chain.roles_join)
    else
      Person.in_group(group, chain.roles_join)
    end
  end
end
