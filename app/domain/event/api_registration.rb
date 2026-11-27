# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Registers a person for an event via API, like a self registration in the web.
# The outcome is reported without revealing whether the person or registration existed before.
class Event::ApiRegistration
  include ActiveModel::Model

  STATUSES = %w[participant waiting_list pending].freeze

  class_attribute :notify_contact, default: true
  class_attribute :locate_duplicates, default: true

  attr_accessor :event, :answers, :privacy_policy_accepted, :send_confirmation,
    *Event::ApiRegistration::Applicant.person_attributes
  attr_reader :id, :registration_status, :participation

  validate :assert_registration_possible
  validate :assert_applicant_valid
  validate :assert_answers_valid

  def self.human_attribute_name(attr, options = {})
    super(attr, {default: Person.human_attribute_name(attr, options)}.merge(options))
  end

  def save
    return false unless valid?

    Event::Participation.transaction do
      @participation = existing_participation || create_participation
      raise ActiveRecord::Rollback unless @participation
    end
    return false unless @participation

    enqueue_follow_up_jobs if @created
    @registration_status = status_of(participation)
    @id = SecureRandom.uuid
    true
  end

  def send_confirmation?
    send_confirmation.nil? || ActiveModel::Type::Boolean.new.cast(send_confirmation)
  end

  private

  def applicant
    @applicant ||= Applicant.new(event, applicant_values,
      privacy_policy_accepted: privacy_policy_accepted)
  end

  def answer_set
    @answer_set ||= Answers.new(event, answers)
  end

  def applicant_values
    Applicant.person_attributes.index_with { |attr| public_send(attr) }
  end

  # application_possible? includes the rules of wagons, e.g. a course state or event types
  # without applications.
  def assert_registration_possible
    return if event.external_applications? && event.application_possible?

    if event.external_applications? && !event.places_or_waiting_list_available?
      errors.add(:base, :event_full)
    else
      errors.add(:base, :event_not_open)
    end
  end

  def assert_applicant_valid
    applicant.validate(errors)
  end

  def assert_answers_valid
    answer_set.validate(errors)
  end

  def existing_participation
    return unless applicant.existing_person?

    event.participations.find_by(participant: applicant.person)
  end

  def create_participation
    person = applicant.person
    @new_person = person.new_record?
    person.assign_attributes(applicant.updates)
    return copy_errors(person) if (@new_person || person.changed?) && !person.save

    participation = build_participation(person)
    return copy_errors(participation, :answers) unless participation.save

    @place_assigned = place_directly(participation)
    @created = true
    participation
  end

  def enqueue_follow_up_jobs
    # Assigning a place already sends the confirmation.
    if send_confirmation? && !@place_assigned
      Event::ParticipationConfirmationJob.new(participation).enqueue!
    end
    Event::ParticipationNotificationJob.new(participation).enqueue! if notify_contact
    return unless @new_person && locate_duplicates

    Person::DuplicateLocatorJob.new(participation.person.id).enqueue!
  end

  def build_participation(person)
    event.participations.new(participant: person).tap do |participation|
      build_participant_role(participation)
      answer_set.assign_to(participation, person.language)
      participation.init_application
      participation.active = !participation.applying_participant?
    end
  end

  def build_participant_role(participation)
    role = participation.roles.build(type: event.class.participant_types.first.sti_name)
    role.participation = participation
  end

  def copy_errors(record, attribute = :base)
    record.errors.each { |error| errors.add(attribute, error.type, message: error.message) }
    nil
  end

  def place_directly(participation)
    Event::ParticipantAssigner.new(event, participation, send_confirmation?).assign_directly
  end

  def status_of(participation)
    if participation.active?
      "participant"
    elsif participation.waiting_list?
      "waiting_list"
    else
      "pending"
    end
  end
end
