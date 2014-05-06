# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationMailer < ActionMailer::Base

  CONTENT_CONFIRMATION = 'event_application_confirmation'
  CONTENT_APPROVAL     = 'event_application_approval'

  helper :standard, :layout

  def confirmation(participation)
    person = participation.person

    compose(participation,
            CONTENT_CONFIRMATION,
            [person],
            'recipient-name' => person.greeting_name)
  end

  def approval(participation, recipients)
    compose(participation,
            CONTENT_APPROVAL,
            recipients,
            'participant-name' => participation.person.to_s,
            'recipient-names'  => recipients.collect(&:greeting_name).join(', '))
  end

  private

  def compose(participation, content_key, recipients, values = {})
    @participation = participation
    @event = participation.event

    content = CustomContent.get(content_key)
    values['event-details']   = event_details
    values['application-url'] = "<a href=\"#{participation_url}\">#{participation_url}</a>"

    mail(to: Person.mailing_emails_for(recipients), subject: content.subject) do |format|
      format.html { render text: content.body_with_values(values) }
    end
  end

  def participation_url
    group_event_participation_url(@event.groups.first, @event, @participation)
  end

  # rubocop:disable MethodLength
  def event_details
    infos = []
    infos << @event.name
    infos << labeled(:dates)    { @event.dates.map(&:to_s).join('<br/>') }
    infos << labeled(:motto)
    infos << labeled(:cost)
    infos << labeled(:description) { @event.description.gsub("\n", '<br/>') }
    infos << labeled(:location) { @event.location.gsub("\n", '<br/>') }
    infos << labeled(:contact)  { "#{@event.contact}<br/>#{@event.contact.email}" }
    infos << answers_details
    infos << additional_information_details
    infos << participation_details
    infos.compact.join('<br/><br/>')
  end
  # rubocop:enable MethodLength

  def labeled(key)
    value = @event.send(key).presence
    if value
      label = @event.class.human_attribute_name(key)
      formatted = block_given? ? yield : value
      "#{label}:<br/>#{formatted}"
    end
  end

  def answers_details
    if @participation.answers.present?
      text = ["#{Event::Participation.human_attribute_name(:answers)}:"]
      @participation.answers.each do |a|
        text << "#{a.question.question}: #{a.answer}"
      end
      text.join('<br/>')
    end
  end

  def additional_information_details
    if @participation.additional_information?
      t('activerecord.attributes.event/participation.additional_information') +
      ':<br/>' +
      @participation.additional_information.gsub("\n", '<br/>')
    end
  end

  def participation_details
    ["#{Event::Role::Participant.model_name.human}:",
     @participation.person.decorate.complete_contact].join('<br/>')
  end

end
