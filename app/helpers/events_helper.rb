# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module EventsHelper

  def format_training_days(event)
    number_with_precision(event.training_days, precision: 1)
  end

  def button_action_event_apply(event, group = nil)
    participation = event.participations.new
    participation.person = current_user

    if event.application_possible? && can?(:new, participation)
      group ||= event.groups.first

      Dropdown::Event::ParticipantAdd.for_user(self, group, event, current_user)
    end
  end

  def typed_group_events_path(group, event_type, options = {})
    path = "#{event_type.type_name}_group_events_path"
    send(path, group, options)
  end

  def application_approve_role_exists?
    Role.types_with_permission(:approve_applications).present?
  end

  def format_event_application_conditions(entry)
    texts = [entry.application_conditions]
    texts.unshift(entry.kind.application_conditions) if entry.course_kind?
    safe_join(texts.select(&:present?).map { |text| simple_format(text) })
  end

end
