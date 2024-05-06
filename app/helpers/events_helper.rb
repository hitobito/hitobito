#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module EventsHelper

  def new_event_button
    event_type = find_event_type
    return unless event_type

    event = event_type.new
    event.groups << @group
    if can?(:new, event)
      action_button(t("events.global.link.add_#{event_type.name.underscore}"),
                    new_group_event_path(@group, event: { type: event_type.sti_name }),
                    :plus)
    end
  end

  def export_events_ical_button
    type = params[:type].presence || 'Event'
    if can?(:"export_#{type.underscore.pluralize}", @group)
      action_button(I18n.t('event.lists.courses.ical_export_button'),
                    params.merge(format: :ics), :'calendar-alt')
    end
  end

  def export_events_button
    type = params[:type].presence || 'Event'
    if can?(:"export_#{type.underscore.pluralize}", @group)
      Dropdown::Event::EventsExport.new(self, params).to_s
    end
  end

  def event_user_application_possible?(event, person = current_user)
    participation = event.participations.new
    participation.person = person

    event.application_possible? && can?(:new, participation)
  end

  def button_action_event_apply(event, group = nil)
    if event_user_application_possible?(event)
      group ||= event.groups.first

      button = Dropdown::Event::ParticipantAdd.for_user(self, group, event, current_user)
      if event.application_closing_at.present?
        button ||= t('event_decorator.apply')
        button += content_tag(:div, t('event.lists.apply_until',
                                      date: f(event.application_closing_at)))
      end
      button
    end
  end

  def typed_group_events_path(group, event_type, options = {})
    path = "#{event_type.type_name}_group_events_path"
    send(path, group, options)
  end

  def shared_access_token_event_url(group, event)
    group_event_url(group, event, shared_access_token: event.shared_access_token)
  end

  def application_approve_role_exists?
    Role.types_with_permission(:approve_applications).present?
  end

  def course_states_used?
    Event::Course.possible_states.present?
  end

  def course_state_collection
    Event::Course.possible_states.map { |state| [course_state_translated(state), state] }
  end

  def course_state_translated(state = nil)
    if course_states_used? && state
      t("activerecord.attributes.event/course.states.#{state}")
    else
      state
    end
  end

  def course_groups
    Group.course_offerers
  end

  def quick_select_course_groups
    (current_user.groups.course_offerers +
     current_user.primary_group&.hierarchy&.course_offerers.to_a).
      uniq
  end

  def format_training_days(event)
    number_to_condensed(event.training_days)
  end

  def format_event_application_conditions(entry)
    texts = [entry.application_conditions]
    texts.unshift(entry.kind.application_conditions) if entry.course_kind?
    html = texts.uniq.select(&:present?).map do |text|
      safe_auto_link(text, html: { target: '_blank' })
    end
    safe_join(html, tag.br)
  end

  def format_event_state(event)
    event.state_translated
  end

  def format_event_group_ids(event)
    groups = event.groups
    linker = lambda do |group|
      link_to_if(assoc_link?(group), group.with_layer.map(&:display_name).join(' / '), group)
    end

    if groups.one?
      linker[groups.first]
    elsif groups.present?
      simple_list(groups) { |group| linker[group] }
    end
  end

  def render_event_contact_attr_fields?
    entry.participant_types.present? &&
      entry.used_attributes(:required_contact_attrs, :hidden_contact_attrs).any?
  end

  def attachment_visibility_button(attachment, visibility)
    label = I18n.t(visibility, scope: 'activerecord.attributes.event/attachment.visibilities')
    active = attachment.visibility.to_s == visibility.to_s
    new_visibility = active ? '' : visibility
    path = group_event_attachment_path(@group, @event, attachment,
                                       'event_attachment[visibility]': new_visibility)

    link_to attachment_visibility_icon(visibility, active), path, class: 'action mr-2',
            title: label, alt: label, data: { method: :put, remote: true }
  end

  def readable_attachments(event, person)
    return event.attachments if can?(:update, event)
    return event.attachments.visible_for_team if event_team?(event, person)
    return event.attachments.visible_for_participants if event_participant?(event, person)
    event.attachments.visible_globally
  end

  private

  def find_event_type
    @group.event_types.find do |t|
      (params[:type].blank? && t == Event) || t.sti_name == params[:type]
    end
  end

  def attachment_visibility_icon(visibility, active)
    icons = { team: :'user-graduate', participants: :users, global: :globe }
    icon(icons[visibility.to_sym], class: active ? '' : 'muted')
  end

  def event_team?(event, person)
    return unless person
    team = event.role_types.select { |role_type| role_type.leader? || role_type.helper? }
    event.participations_for(*team).pluck(:person_id).include?(person.id)
  end

  def event_participant?(event, person)
    return unless person
    event.participations.pluck(:person_id).include?(person.id)
  end

end
