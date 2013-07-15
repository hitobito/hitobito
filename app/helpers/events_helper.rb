module EventsHelper

  def button_action_event_apply(event, group = nil)
    participation = event.participations.new
    participation.person = current_user

    if event.application_possible? && can?(:new, participation)
       group ||= event.groups.first
       action_button 'Anmelden', new_group_event_participation_path(group, event), :check
     end
  end

  def typed_group_events_path(group, event_type, options = {})
    path = "#{event_type.type_name}_group_events_path"
    send(path, group, options)
  end

end