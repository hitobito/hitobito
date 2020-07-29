# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventDecorator < ApplicationDecorator
  decorates :event
  decorates_association :contact

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
    if maximum_participants.to_i > 0
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
      h.simple_format(h.truncate(model.description, length: 60))
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

  def new_role
    p = participations.new
    role = p.roles.new
    role.participation = p
    role
  end

  def issued_qualifications_info_for_leaders
    qualis = kind.qualification_kinds('qualification', 'leader').list.to_a
    prolongs = kind.qualification_kinds('prolongation', 'leader').list.to_a
    variables = { until: quali_date,
                  model: quali_model_name(qualis),
                  issued: qualis.join(', '),
                  prolonged: prolongs.join(', '),
                  count: prolongs.size }

    translate_issued_qualifications_info(qualis, prolongs, variables)
  end

  def issued_qualifications_info_for_participants
    qualis = kind.qualification_kinds('qualification', 'participant').list.to_a
    prolongs = kind.qualification_kinds('prolongation', 'participant').list.to_a
    variables = { until: quali_date,
                  model: quali_model_name(qualis),
                  issued: qualis.join(', '),
                  prolonged: prolongs.join(', '),
                  count: prolongs.size }

    translate_issued_qualifications_info(qualis, prolongs, variables)
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

  private

  def translate_issued_qualifications_info(qualis, prolongs, variables)
    if qualis.present? && prolongs.present?
      translate(:issue_and_prolong, variables)
    elsif qualis.present?
      translate(:issue_only, variables)
    elsif prolongs.present?
      translate(:prolong_only, variables)
    else
      ''
    end
  end

  def quali_model_name(list)
    Qualification.model_name.human(count: list.size)
  end

  def quali_date
    h.f(qualification_date)
  end

end
