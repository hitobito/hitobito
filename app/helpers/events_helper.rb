module EventsHelper
  
  def button_action_event_apply(event, group = nil)
    participation = event.participations.new
    participation.person = current_user
    
    if event.application_possible? && can?(:new, participation)
       group ||= event.groups.first
       action_button 'Anmelden', new_group_event_participation_path(group, event), :check
     end
  end
end