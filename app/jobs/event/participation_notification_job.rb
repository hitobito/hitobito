# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationNotificationJob < BaseJob
  self.parameters = [:participation_id, :locale]

  def initialize(participation)
    super()
    @participation_id = participation.id
  end

  def perform
    return unless participation # may have been deleted again

    LocaleSetter.with_locale(person: participation.person) do
      send_notification
    end
  end

  private

  def send_notification
    return unless notify_contact?(participation.event)

    Event::ParticipationMailer.notify_contact(participation,
      participation.event.contact).deliver_now
  rescue StandardError => exception
    # Log more explicitly here to help debugging NoMethodError
    Raven.capture_exception(exception,
      logger: "participation_notification",
      extra: {event: participation.event.attributes.to_s})
    raise exception
  end

  def notify_contact?(event)
    event.notify_contact_on_participations? &&
      event.contact.present? &&
      MailRelay::AddressList.new(event.contact).entries.any?
  end

  def participation
    @participation ||= Event::Participation.find(@participation_id)
  end
end
