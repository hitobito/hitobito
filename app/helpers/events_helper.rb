# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module EventsHelper

  def button_action_event_apply(event, group = nil)
    participation = event.participations.new
    participation.person = current_user

    if event.application_possible? && can?(:new, participation)
      group ||= event.groups.first
      action_button(t('event_decorator.apply'),
                    new_group_event_participation_path(group, event),
                    :check)
    end
  end

  def typed_group_events_path(group, event_type, options = {})
    path = "#{event_type.type_name}_group_events_path"
    send(path, group, options)
  end

  def application_approve_role_exists?
    Role.types_with_permission(:approve_applications).present?
  end

end
