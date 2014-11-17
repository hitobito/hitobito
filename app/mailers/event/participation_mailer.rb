# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationMailer < ApplicationMailer

  CONTENT_CONFIRMATION = 'event_application_confirmation'
  CONTENT_APPROVAL     = 'event_application_approval'

  # Include all helpers that are required directly or indirectly (in decorators)
  helper :standard, :layout, :auto_link

  attr_reader :participation

  def confirmation(participation)
    @participation = participation

    filename = Export::Pdf::Participation.filename(participation)
    attachments[filename] = Export::Pdf::Participation.render(participation)

    compose(CONTENT_CONFIRMATION,
            [person],
            'recipient-name' => person.greeting_name)
  end

  def approval(participation, recipients)
    @participation = participation

    compose(CONTENT_APPROVAL,
            recipients,
            'participant-name' => person.to_s,
            'recipient-names'  => recipients.collect(&:greeting_name).join(', '))
  end

  private

  def compose(content_key, recipients, values = {})
    # Assert the current mailer's view context is stored as Draper::ViewContext.
    # This is done in the #view_context method overriden by Draper.
    # Otherwise, decorators will not have access to all helper methods.
    view_context

    content = CustomContent.get(content_key)
    values['event-details']   = event_details
    values['application-url'] = "<a href=\"#{participation_url}\">#{participation_url}</a>"

    mail(to: Person.mailing_emails_for(recipients), subject: content.subject) do |format|
      format.html { render text: content.body_with_values(values) }
    end
  end

  def participation_url
    group_event_participation_url(event.groups.first, event, participation)
  end

  # rubocop:disable MethodLength
  def event_details
    infos = []
    infos << event.name
    infos << labeled(:dates)    { event.dates.map(&:to_s).join('<br/>') }
    infos << labeled(:motto)
    infos << labeled(:cost)
    infos << labeled(:description) { event.description.gsub("\n", '<br/>') }
    infos << labeled(:location) { event.location.gsub("\n", '<br/>') }
    infos << labeled(:contact)  { "#{event.contact}<br/>#{event.contact.email}" }
    infos << answers_details
    infos << additional_information_details
    infos << participation_details
    infos.compact.join('<br/><br/>')
  end
  # rubocop:enable MethodLength

  def labeled(key)
    value = event.send(key).presence
    if value
      label = event.class.human_attribute_name(key)
      formatted = block_given? ? yield : value
      "#{label}:<br/>#{formatted}"
    end
  end

  def answers_details
    if participation.answers.present?
      text = ["#{Event::Participation.human_attribute_name(:answers)}:"]
      participation.answers.each do |a|
        text << "#{a.question.question}: #{a.answer}"
      end
      text.join('<br/>')
    end
  end

  def additional_information_details
    if participation.additional_information?
      t('activerecord.attributes.event/participation.additional_information') +
      ':<br/>' +
      participation.additional_information.gsub("\n", '<br/>')
    end
  end

  def participation_details
    ["#{Event::Role::Participant.model_name.human}:",
     person.decorate.complete_contact].join('<br/>')
  end

  def person
    participation.person
  end

  def event
    participation.event
  end

end
