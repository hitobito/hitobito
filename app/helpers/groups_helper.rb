# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module GroupsHelper

  # def new_event_button
  #   event_type = find_event_type
  #   return unless event_type

  #   event = event_type.new
  #   event.groups << @group
  #   if can?(:new, event)
  #     action_button(t("events.global.link.add_#{event_type.name.underscore}"),
  #                   new_group_event_path(@group, event: { type: event_type.sti_name }),
  #                   :plus)
  #   end
  # end

  def export_events_ical_button
    type = params[:type].presence || 'Event'
    if can?(:"export_#{type.underscore.pluralize}", @group)
      action_button(I18n.t('event.lists.courses.ical_export_button'),
        params.merge(format: :ics), :calendar)
    end
  end

  def export_events_button
    type = params[:type].presence || 'Event'
    if can?(:"export_#{type.underscore.pluralize}", @group)
      action_button(I18n.t('event.lists.courses.csv_export_button'),
                    params.merge(format: :csv), :download)
    end
  end

  def tab_person_add_request_label(group)
    label = t('activerecord.models.person/add_request.other')
    count = Person::AddRequest.for_layer(group).count
    label << " (#{count})" if count > 0
    label.html_safe
  end

end
