# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventDecorator < ApplicationDecorator
  decorates :event
  decorates_association :contact
  decorates_association :kind

  class_attribute :icons
  self.icons = {
    'Event::Course' => 'book'
  }

  def label
    safe_join([name, label_detail], h.tag(:br))
  end

  def labeled_link(url = nil, can = nil)
    url ||= h.group_event_path(group_ids.first, model)
    can = can?(:show, model) if can.nil?
    safe_join([h.link_to_if(can, name, url), h.muted(model.label_detail)], h.tag(:br))
  end

  def dates_info
    safe_join(dates, h.tag(:br)) { |date| date.duration }
  end

  def dates_full
    # adding #to_a avoids irregularly occuring, inexplicable
    # "undefined method `duration' for #<Proc:0x00000004d6dd38>" errors
    safe_join(dates.to_a, h.tag(:br)) do |date|
      safe_join([date.duration, h.muted(date.label_and_location)], ' ')
    end
  end

  def booking_info
    if maximum_participants.to_i.positive?
      translate(:participants_info_with_limit, count: applicant_count,
                                               limit: maximum_participants.to_i)
    else
      translate(:participants_info, count: applicant_count)
    end
  end

  def active_participants_info
    translate(:active_participants_info, count: participant_count)
  end

  def state_translated(state = model.state)
    if possible_states.present? && state
      h.t("activerecord.attributes.#{model.class.name.underscore}.states.#{state}")
    else
      state
    end
  end

  def state_collection
    possible_states.collect { |s| Struct.new(:id, :to_s).new(s, state_translated(s)) }
  end

  def description_short
    if model.description?
      h.truncate(h.strip_tags(model.description), length: 60)
    end
  end

  def external_application_link(group)
    if external_applications?
      url = h.group_public_event_url(group, id)
      h.link_to(url, url)
    else
      translate(:not_possible)
    end
  end

  def issued_qualifications_info_for_leaders
    kind.issued_qualifications_info_for_leaders(qualification_date)
  end

  def issued_qualifications_info_for_participants
    kind.issued_qualifications_info_for_participants(qualification_date)
  end

  def new_role
    p = participations.new
    role = p.roles.new
    role.participation = p
    role
  end

  def as_typeahead
    groups_label = groups.first.to_s
    if groups.size > 1
      groups_label = h.truncate(groups.join(', '), count: 50, separator: ',')
    end
    { id: id, label: "#{model} (#{groups_label})" }
  end

  def as_quicksearch
    { id: id, label: label_with_group, type: :event, icon: icons.fetch(type, 'calendar-alt') }
  end

  def label_with_group
    label = to_s
    label += " (#{number})" if number?
    h.safe_join([groups.first.to_s, label], ': ')
  end

  def any_conditions_present?
    course_kind? ||
      (object.used_attributes.include?(:application_conditions) &&
       application_conditions.present?)
  end
end
