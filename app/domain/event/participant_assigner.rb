# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipantAssigner < Struct.new(:event, :participation)

  def createable?
    participation.event.id == event.id || (!participating?(event) && !participating?(participation.event))
  end

  def create_role
    Event::Participation.transaction do
      unless participation.event_id == event.id
        update_participation_event
        update_answers
      end

      create_participant_role
    end
    event.reload
  end

  def remove_role
    participation.roles.where(type: event.participant_type.sti_name).destroy_all
    update_participation_event(participation.application.priority_1)
    event.reload
  end

  private

  def participating?(event)
    event.participations_for(event.participant_type).where(person_id: participation.person_id).exists?
  end

  def update_participation_event(e = event)
    old_event = participation.event

    participation.event = e
    participation.update_column(:event_id, e.id)

    if e != old_event.id
      old_event.refresh_representative_participant_count!
    end
    e.refresh_representative_participant_count!
  end

  def create_participant_role
    role = event.participant_type.new
    role.participation = participation
    role.save!
  end

  # update the existing set of answers so that one exists for every question of event.
  def update_answers
    current_answers = participation.answers.includes(:question)
    event.questions.each do |q|
      exists = current_answers.any? do|a|
        a.question.question == q.question &&
        a.question.choice_items == q.choice_items
      end
      participation.answers.create(question_id: q.id) unless exists
    end
  end
end
