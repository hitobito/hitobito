# encoding: utf-8

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

  def person_additional_information
    h.tag(:br) + h.muted(person.additional_name) + incomplete_label
  end

  def person_location_information
    [layer_group, town_info].reject(&:blank?).join(" ")
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
    "(#{h.t('.town')}: #{person.town})" if person.town
  end

end
