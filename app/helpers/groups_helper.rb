# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module GroupsHelper

  def new_event_button
    event = @group.events.new
    event.groups << @group
    if can?(:new, event)
      event_type = (params[:type] && params[:type].constantize) || Event

      if @group.event_types.include?(event_type)
        action_button(ti(:'link.add', model: event_type.model_name.human),
                      new_group_event_path(@group, event: { type: event_type.sti_name }),
                      :plus)
      end
    end
  end

  def export_event_button
    if can?(:export_events, @group)
      action_button(I18n.t('event.lists.courses.csv_export_button'),
                    params.merge(format: :csv), :download)
    end
  end

end
