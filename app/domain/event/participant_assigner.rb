# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipantAssigner
  attr_reader :target_event, :participation, :send_email, :user

  delegate :application, to: :participation

  def initialize(participation, target_event: participation.event, send_email: true, user: nil)
    @participation = participation
    @target_event = target_event
    @send_email = send_email
    @user = user
  end

  def createable?
    !moving? || !(applied_to?(target_event) || participant_of?(current_event))
  end

  def assign_directly?
    target_event.places_available? &&
      target_event.attr_used?(:automatic_assignment) && target_event.automatic_assignment?
  end

  # Returns whether a place was assigned, including its confirmation.
  def assign_directly(wanted = assign_directly?)
    return false unless wanted && target_event.supports_applications? && createable?

    add_participant
    true
  end

  def add_participant
    Event::Participation.transaction do
      if moving?
        move_participation_to(target_event)
        copy_answers_to_target_questions
      end

      set_active(true)
      remove_from_waiting_list if application&.waiting_list?
      create_participant_role
      target_event.refresh_participant_counts!
      send_confirmation if send_email
    end
    target_event.reload
  end

  def remove_participant
    Event::Participation.transaction do
      set_active(false)
      destroy_roles_other_than_participant
      first_priority_event = application.priority_1 || current_event
      move_participation_to(first_priority_event)
      first_priority_event.refresh_participant_counts!
      send_confirmation if send_email
    end
    target_event.reload
  end

  private

  # Read live, since moving the participation changes it.
  def current_event
    participation.event
  end

  def moving?
    current_event.id != target_event.id
  end

  def participant_of?(event)
    participations_with_participant_role(event).active.exists?
  end

  def applied_to?(event)
    participations_with_participant_role(event).exists?
  end

  def participations_with_participant_role(event)
    event.participations
      .joins(:roles)
      .where(event_roles: {type: event.participant_types.map(&:sti_name)})
      .where(participant: participation.participant)
  end

  def create_participant_role
    unless participation.roles.exists?
      role = target_event.participant_types.first.new
      role.participation = participation
      role.save!
    end
  end

  def destroy_roles_other_than_participant
    participation.roles.where.not(type: target_event.participant_types.map(&:sti_name)).destroy_all
  end

  def move_participation_to(new_event)
    old_event = current_event
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

  def copy_answers_to_target_questions
    answers = participation.answers.includes(:question)
    target_event.questions.each do |question|
      answer = answers.find { |a| same_question?(a.question, question) }
      if answer
        answer.update(question: question)
      else
        participation.answers.create(question_id: question.id)
      end
    end
  end

  def same_question?(one, other)
    one.question == other.question &&
      one.choices == other.choices &&
      one.multiple_choices? == other.multiple_choices?
  end

  def send_confirmation
    Event::ParticipationConfirmationJob.new(participation).enqueue!
  end
end
