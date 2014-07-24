# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module EventParticipationsHelper

  def format_event_participation_created_at(participation)
    f(participation.created_at.to_date)
  end

  def event_participations_roles_header(t, p)
    header = t.sort_header(:roles, Role.model_name.human(count: 2))

    if can?(:update, entries.first)
      header += " | #{Event::Participation.human_attribute_name(:created_at)}"
    end

    header
  end

  def event_participations_roles_content(p)
    content = p.roles_short

    if can?(:update, entries.first)
      content += content_tag(:p, f(p.created_at.to_date))
    end

    content
  end

  def event_participation_attr_list
    [:birthday, :gender, (can?(:show_details, entry) ? :created_at : nil)].compact
  end
end

