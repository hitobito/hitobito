# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationMailer < ApplicationMailer

  CONTENT_CONFIRMATION = 'event_application_confirmation'.freeze
  CONTENT_APPROVAL     = 'event_application_approval'.freeze
  CONTENT_CANCEL       = 'event_cancel_application'.freeze

  # Include all helpers that are required directly or indirectly (in decorators)
  helper :format, :layout, :auto_link_value

  attr_reader :participation

  def confirmation(participation)
    @participation = participation

    filename = Export::Pdf::Participation.filename(participation)
    attachments[filename] = Export::Pdf::Participation.render(participation)

    compose(person, CONTENT_CONFIRMATION)
  end

  def approval(participation, recipients)
    @participation = participation
    @recipients    = recipients

    compose(@recipients, CONTENT_APPROVAL)
  end

  def cancel(event, person)
    @event = event
    @person = person

    custom_content_mail(@person, CONTENT_CANCEL, values_for_placeholders(CONTENT_CANCEL))
  end

  private

  def placeholder_recipient_name
    person.greeting_name
  end

  def placeholder_participant_name
    person.to_s
  end

  def placeholder_recipient_names
    @recipients.collect(&:greeting_name).join(', ')
  end

  def placeholder_event_details
    if participation.nil?
      event_without_participation
    else
      event_details
    end
  end

  def placeholder_application_url
    link_to(participation_url)
  end

  def compose(recipients, content_key, values = nil)
    # Assert the current mailer's view context is stored as Draper::ViewContext.
    # This is done in the #view_context method overriden by Draper.
    # Otherwise, decorators will not have access to all helper methods.
    view_context

    values = if values
               values.merge(
                 'event-details'   => event_details,
                 'application-url' => link_to(participation_url)
               )
             else
               values_for_placeholders(content_key)
             end

    custom_content_mail(recipients, content_key, values)
  end

  def participation_url
    group_event_participation_url(event.groups.first, event, participation)
  end

  # rubocop:disable MethodLength, Metrics/AbcSize
  def event_details
    infos = []
    infos << event.name
    infos << labeled(:dates) { event.dates.map(&:to_s).join('<br/>') }
    infos << labeled(:motto)
    infos << labeled(:cost)
    infos << labeled(:description) { event.description.gsub("\n", '<br/>') }
    infos << labeled(:location) { event.location.gsub("\n", '<br/>') }
    infos << labeled(:contact) { "#{event.contact}<br/>#{event.contact.email}" }
    infos << answers_details
    infos << additional_information_details
    infos << participation_details
    infos.compact.join('<br/><br/>')
  end
  # rubocop:enable MethodLength, Metrics/AbcSize

  def event_without_participation
    infos = []
    infos << event.name
    infos << labeled(:dates) { event.dates.map(&:to_s).join('<br/>') }
    infos.compact.join('<br/><br/>')
  end

  def labeled(key)
    value = event.send(key).presence
    if value
      label = event.class.human_attribute_name(key)
      formatted = block_given? ? yield : value
      "#{label}:<br/>#{formatted}"
    end
  end

  def answers_details
    answers = load_application_answers
    if answers.present?
      text = ["#{Event::Participation.human_attribute_name(:answers)}:"]
      answers.each do |a|
        text << "#{a.question.question}: #{a.answer}"
      end
      text.join('<br/>')
    end
  end

  def load_application_answers
    participation.answers
      .joins(:question)
      .includes(:question)
      .where(event_questions: { admin: false })
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
    @person ||= participation.person
  end

  def event
    @event ||= participation.event
  end

end
