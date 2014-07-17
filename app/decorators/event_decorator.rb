# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventDecorator < ApplicationDecorator
  decorates :event
  decorates_association :contact

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
    safe_join(dates, h.tag(:br)) do |date|
      safe_join([date.duration, h.muted(date.label_and_location)], ' ')
    end
  end

  def booking_info
    if maximum_participants.to_i > 0
      translate(:participants_info_with_limit, count: representative_participant_count.to_s,
                                               limit: maximum_participants.to_i)
    else
      translate(:participants_info, count: representative_participant_count.to_s)
    end
  end

  def active_participants_info
    translate(:active_participants_info, count: participant_count.to_s)
  end

  def state_translated(state = model.state)
    h.t("activerecord.attributes.event/course.states.#{state}") if state
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
      url = h.register_group_event_url(group, id)
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
