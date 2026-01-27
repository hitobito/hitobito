#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationDecorator < ApplicationDecorator
  decorates "event/participation"

  decorates_association :person
  decorates_association :event, with: EventDecorator
  decorates_association :application

  delegate :to_s, :email, :primary_email, :all_emails, :all_additional_emails,
    :all_phone_numbers, :all_social_accounts, :complete_address, :town, :layer_group_label,
    :layer_group, to: :person

  delegate :dates_full, to: :event

  def person_additional_information
    h.tag(:br) + h.muted(person.additional_name) + incomplete_label
  end

  def labeled_link(label = nil)
    label = label.presence || model.model_name.human
    url = h.group_event_participation_path(event.groups.first, event, model)
    h.link_to_if(can?(:show, model), label, url)
  end

  def person_location_information
    [layer_group, town_info].compact_blank.join(" ")
  end

  def incomplete_label
    if answers.any? { |answer| answer.question.required? && answer.answer.blank? }
      content_tag(:div, h.t(".incomplete"), class: "text-warning")
    end
  end

  # render a list of all participations
  def roles_short
    h.safe_join(roles) do |r|
      content_tag(:p, r)
    end
  end

  def list_roles
    safe_join(roles, h.tag(:br)) { |role| role.to_s }
  end

  def town_info
    "(#{h.t(".town")}: #{person.town})" if participant.town.present?
  end

  def guests_allowed?
    allowed_guests > 0
  end

  def allowed_guests
    event_guest_limiter.remaining
  end

  def event_guest_limiter
    @event_guest_limiter ||= Events::GuestLimiter.for(event, self)
  end
end
