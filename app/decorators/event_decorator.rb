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
    safe_join(dates, h.tag(:br)) { |date| safe_join([date.duration, h.muted(label_and_location(date))], ' ') }
  end

  def booking_info
    info = "#{participant_count.to_s} Anmeldungen"
    info << " für #{maximum_participants} Plätze" if maximum_participants.to_i > 0
    info
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
      'nicht möglich'
    end
  end

  def new_role
    p = participations.new
    role = p.roles.new
    role.participation = p
    role
  end

  def issued_qualifications_info_for_leaders
    prolongs = kind.qualification_kinds.list.to_a
    info = ''
    if prolongs.present?
      info << 'Verlängert'
      info << issued_prolongations_info(prolongs)
      info << " auf den #{h.f(qualification_date)} (letztes Kursdatum)."
    end
    info
  end

  def issued_qualifications_info_for_participants
    qualis = kind.qualification_kinds.list.to_a
    prolongs = kind.prolongations.list.to_a
    info = ''
    info << issued_qualifications_info(qualis)
    if prolongs.present?
      if qualis.present?
        info << ' und verlängert'
      else
        info << 'Verlängert'
      end
    end
    info << issued_prolongations_info(prolongs)
    if prolongs.present? || qualis.present?
      info << " auf den #{h.f(qualification_date)} (letztes Kursdatum)."
    end
    info
  end

  def as_typeahead
    groups_label = groups.first.to_s
    if groups.size > 1
      groups_label = h.truncate(groups.join(', '), count: 50, separator: ',')
    end
    { id: id, label: "#{model.to_s} (#{groups_label})" }
  end

  private

  def label_and_location(date)
    [date.label, date.location].compact.reject(&:empty?).join(', ')
  end

  def issued_qualifications_info(qualification_kinds)
    info = ''
    if qualification_kinds.present?
      info << 'Vergibt die Qualifikation'
      info << 'en' if qualification_kinds.size > 1
      info << ' '
      info << qualification_kinds.join(', ')
    end
    info
  end

  def issued_prolongations_info(qualification_kinds)
    info = ''
    if qualification_kinds.present?
      info << ' existierende Qualifikationen '
      info << qualification_kinds.join(', ')
    end
    info
  end

end
