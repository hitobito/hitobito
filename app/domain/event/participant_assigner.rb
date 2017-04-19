# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipantAssigner

  attr_reader :event, :participation, :user

  delegate :application, to: :participation

  def initialize(event, participation, user = nil)
    @event = event
    @participation = participation
    @user = user
  end

  def createable?
    participation.event.id == event.id ||
      !(applied?(event) || participating?(participation.event))
  end

  def add_participant
    Event::Participation.transaction do
      unless participation.event_id == event.id
        update_participation_event(event)
        update_answers
      end

      set_active(true)
      remove_from_waiting_list if application.waiting_list?
      create_participant_role
      event.refresh_participant_counts!
    end
    event.reload
  end

  def remove_participant
    Event::Participation.transaction do
      set_active(false)
      # destroy all other roles when removing a participant
      participation.roles.where.not(type: event.participant_types.collect(&:sti_name)).destroy_all
      original_event = participation.application.priority_1
      update_participation_event(original_event)
      original_event.refresh_participant_counts!
    end
    event.reload
  end

  private

  def participating?(event)
    event.participations
         .active # only active/assigned participations are relevant
         .joins(:roles)
         .where(event_roles: { type: event.participant_types.map(&:sti_name) })
         .where(person_id: participation.person_id)
         .exists?
  end

  def applied?(event)
    event.participations
         .joins(:roles)
         .where(event_roles: { type: event.participant_types.map(&:sti_name) })
         .where(person_id: participation.person_id)
         .exists?
  end

  def create_participant_role
    unless participation.roles.exists?
      role = event.participant_types.first.new
      role.participation = participation
      role.save!
    end
  end

  def update_participation_event(new_event)
    old_event = participation.event
    unless old_event.id == new_event.id
      participation.event = new_event
      participation.update_column(:event_id, new_event.id)
      old_event.refresh_participant_counts!
    end
  end

  def set_active(active)
    participation.update!(active: active)
  end

  def remove_from_waiting_list
    application.update_column(:waiting_list, false)
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
