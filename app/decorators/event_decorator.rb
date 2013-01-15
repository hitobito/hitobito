# encoding: utf-8

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
    safe_join(dates, h.tag(:br)) { |date| safe_join([date.duration, h.muted(date.label)], ' ') }
  end

  def booking_info
    info = participant_count.to_s
    info << " von #{maximum_participants}" if maximum_participants.to_i > 0
    info
  end

  def possible_role_links(group)
    klass.role_types.map do |type|
      unless type.restricted
        link = h.new_group_event_role_path(group, self, event_role: { type: type.sti_name })
        h.link_to(type.label, link)
      end
    end.compact
  end

  def preconditions
    model.kind_of?(Event::Course) &&  kind.preconditions.map(&:label)
  end

  def state_translated(state = model.state)
    h.t("activerecord.attributes.event/course.states.#{state}") if state
  end

  def state_collection
    possible_states.collect {|s| Struct.new(:id, :to_s).new(s, state_translated(s)) }
  end

  def description
    h.simple_format(model.description) if model.description?
  end

  def description_short
    if model.description?
      h.simple_format(h.truncate(model.description, length: 60))
    end
  end

  def location
    h.simple_format(model.location) if model.location?
  end

  def issued_qualifications_info
    qualis = kind.qualification_kinds.to_a
    prolongs = kind.prolongations.to_a
    info = ""
    if qualis.present?
      info << "Vergibt die Qualifikation"
      info << "en" if qualis.size > 1
      info << " "
      info << qualis.join(', ')
      if prolongs.present?
        info << " und verlängert"
      end
    end
    if prolongs.present?
      if qualis.blank?
        info << "Verlängert"
      end
      info << " existierende Qualifikationen "
      info << prolongs.join(', ')
    end
    if prolongs.present? || qualis.present?
      info << " auf den #{h.f(qualification_date)} (letztes Kursdatum)."
    end
    info
  end

  def with_br(*attrs)
    values = attrs.map do |attr|
      send(attr).presence
    end.compact
    safe_join(values, h.tag(:br))
  end

  def as_typeahead
    groups_label = groups.first.to_s
    if groups.size > 1
      groups_label = h.truncate(groups.join(', '), count: 50, separator: ',')
    end
    {id: id, label: "#{model.to_s} (#{groups_label})"}
  end

  def kind?
    model.kind_of?(Event::Course) && kind.present?
  end

  def kind_info
    html = ''.html_safe
    html << h.labeled('Mindestalter', kind.minimum_age)
    html << h.labeled('erford. Qualifikationen', quali_kinds)
    content_tag(:dl, class: "dl-horizontal") { html }
  end

  def quali_kinds
    safe_join(kind.qualification_kinds, ', ') { |q| q.to_s }
  end

end
