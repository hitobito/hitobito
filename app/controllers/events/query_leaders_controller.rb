# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Events::QueryLeadersController < Person::QueryController
  self.serializer = :as_basic_typeahead

  private

  def authorize_action
    authorize!(:index_events, group)
  end

  def scope
    super
      .joins(event_participations: :roles)
      .where(event_participations: {event_id: accessible_event_ids},
        event_roles: {type: leader_roles.map(&:sti_name)})
      .distinct
  end

  def accessible_event_ids
    Event
      .accessible_by(EventReadables.new(current_user))
      .in_year(year)
      .joins(:groups)
      .where(groups: {layer_group_id: group.layer_group_id})
      .select(:id)
  end

  def leader_roles
    ([Event] + Event.subclasses).flat_map do |event_type|
      event_type.role_types.select { |role| role.kind == :leader }
    end.uniq
  end

  def year
    @year ||= params[:year].presence || Date.current.year
  end

  def group
    @group ||= Group.find(params[:group_id])
  end
end
