# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito_jubla and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_jubla.

class Event::CancelParticipationJob < BaseJob

  self.parameters = [:event_type, :event_id, :person_id]
  
  def initialize(event, person)
    @event_type = event.class.name
    @event_id = event.id
    @person_id = person.id
  end

  def perform
    Event::ParticipationMailer.cancel_participation(event, person).deliver_now
  end

  def event
    @event_type.constantize.find(@event_id)
  end

  def person
    Person.find(@person_id)
  end

end
