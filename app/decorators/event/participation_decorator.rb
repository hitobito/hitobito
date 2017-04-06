# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationDecorator < ApplicationDecorator
  decorates 'event/participation'

  decorates_association :person
  decorates_association :event, with: EventDecorator
  decorates_association :application

  delegate :to_s, :email, :primary_email, :all_emails, :all_additional_emails,
           :all_phone_numbers, :all_social_accounts, :complete_address, :town, :layer_group_label,
           :layer_group, to: :person
  delegate :qualified?, to: :qualifier

  def person_additional_information
    h.tag(:br) + h.muted(person.additional_name) + incomplete_label
  end

  def person_location_information
    [layer_group, town_info].reject(&:blank?).join(' ')
  end

  def incomplete_label
    if answers.any? { |answer| answer.question.required? && answer.answer.blank? }
      content_tag(:div, h.t('.incomplete'), class: 'text-warning')
    end
  end

  # render a list of all participations
  def roles_short
    h.safe_join(roles) do |r|
      content_tag(:p, r)
    end
  end

  def issue_option(group)
    if qualified.nil? || !qualified?
      qualify_option_icon(group, :put, :ok)
    else
      h.icon(:ok)
    end
  end

  def revoke_option(group)
    if qualified.nil? || qualified?
      qualify_option_icon(group, :delete, :remove)
    else
      h.icon(:remove)
    end
  end

  def qualify_option_icon(group, method, icon)
    if can?(:qualify, event)
      qualify_option_link(group, method, icon)
    else
      qualification_open_option(icon)
    end
  end

  def qualify_option_link(group, method, icon)
    h.link_to(h.group_event_qualification_path(group, event_id, model),
              method: method, remote: true, title: tooltips[icon]) do
      qualification_open_option(icon)
    end
  end

  def qualification_open_option(icon)
    h.content_tag(:i, '', class: "icon icon-#{icon} disabled")
  end

  def qualifier
    Event::Qualifier.for(model)
  end

  def list_roles
    safe_join(roles, h.tag(:br)) { |role| role.to_s }
  end

  def town_info
    "(#{h.t('.town')}: #{person.town})" if person.town
  end

  def tooltips
    @tooltips ||= {
      ok: translate('tooltips.ok'),
      remove: translate('tooltips.remove')
    }
  end

end
