class Event::ParticipationMailer < ActionMailer::Base

  CONTENT_CONFIRMATION = 'event_application_confirmation'
  CONTENT_APPROVAL     = 'event_application_approval'
  
  def confirmation(participation)
    person = participation.person
    
    compose(participation,
            CONTENT_CONFIRMATION,
            person.email,
            'recipient-name' => person.first_name)
  end
  
  def approval(participation, recipients)
    compose(participation, 
            CONTENT_APPROVAL, 
            recipients.collect(&:email).compact,
            'participant-name' => participation.person.to_s,
            'recipient-names'  => recipients.collect(&:first_name).join(', '))
  end

  private
  
  def compose(participation, content_key, recipients, values = {})
    @participation = participation
    @event = participation.event
    
    content = CustomContent.get(content_key)
    values['event-details']   = event_details
    values['application-url'] = "<a href=\"#{participation_url}\">#{participation_url}</a>"

    mail to: recipients, subject: content.subject do |format|
      format.html { render text: content.body_with_values(values) }
    end
  end
  
  def participation_url
    group_event_participation_url(@event.groups.first, @event, @participation)
  end

  def event_details
    infos = []
    infos << @event.name
    infos << labeled(:contact)  { "#{@event.contact}<br/>#{@event.contact.email}" }
    infos << labeled(:dates)    { @event.dates.map(&:to_s).join("<br/>") } 
    infos << labeled(:location) { @event.location.gsub("\n", "<br/>") } 
    infos.compact.join("<br/><br/>")
  end

  def labeled(key) 
    if value = @event.send(key).presence
      label = @event.class.human_attribute_name(key)
      formatted = block_given? ? yield : value
      "#{label}:<br/>#{formatted}"
    end
  end

end
