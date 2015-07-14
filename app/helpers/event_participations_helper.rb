# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module EventParticipationsHelper

  def format_event_participation_created_at(participation)
    f(participation.created_at.to_date)
  end

  def event_participations_roles_header(t)
    headers = [t.sort_header(:roles, Role.model_name.human(count: 2))]

    if can?(:update, entries.first)
      headers << [t.sort_header(:created_at, Event::Participation.human_attribute_name(:created_at))]
    end

    headers.join(' | ').html_safe
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

  def precondition_warnings_badge(p)
    if p.event.supports_applications && p.event.course_kind?
      checker = Event::PreconditionChecker.new(p.event, current_user)
      unless checker.valid?
        title = checker.errors_text_without_title.flatten.join('; ')
        content_tag(:div, class: 'badge badge-warning', title: title) do
          I18n.t('event.participations.list.preconditions_not_met')
        end
      end
    end
  end
end
