# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Wizards::RegisterNewUserWizard < Wizards::Base
  self.steps = [Wizards::Steps::NewUserForm]

  def initialize(group:, current_step: 0, **params)
    super(current_step: current_step, **params)
    @group = group
  end

  def person
    @person ||= build_person
  end

  def role
    person.roles.first
  end

  def save!
    person.save!
    enqueue_duplicate_locator_job
    enqueue_notification_email
    send_password_reset_email
  end

  def requires_adult_consent? = group.self_registration_require_adult_consent

  def policy_finder = Group::PrivacyPolicyFinder.for(group: group)

  def requires_policy_acceptance? = policy_finder.acceptance_needed?

  private

  def build_person
    Person.new(person_attributes).tap do |person|
      person.primary_group = group
      role = person.roles.build(group: group, type: group.self_registration_role_type)
      yield person, role if block_given?
    end
  end

  def person_attributes
    new_user_form.attributes.except("adult_consent")
  end

  def enqueue_duplicate_locator_job
    Person::DuplicateLocatorJob.new(person.id).enqueue!
  end

  def enqueue_notification_email
    return if group.self_registration_notification_email.blank?

    Groups::SelfRegistrationNotificationMailer
      .self_registration_notification(group.self_registration_notification_email, role)
      .deliver_later
  end

  def send_password_reset_email
    return if person.email.blank?

    Person.send_reset_password_instructions(email: person.email)
  end

  attr_reader :group
end
