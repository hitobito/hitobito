# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Wizards::RegisterNewEventGuestWizard < Wizards::Base
  self.steps = [
    Wizards::Steps::NewEventGuestContactDataForm,
    Wizards::Steps::NewEventGuestParticipationForm
  ]

  attr_reader :event
  attr_reader :guest_of

  delegate(*Event.possible_contact_attrs, to: :guest)
  delegate(:phone_number, to: :guest)

  def initialize(group:, event:, guest_of:, current_ability: nil, current_step: 0, **params)
    @group = group
    @event = event
    @guest_of = guest_of
    super(current_step:, current_ability:, **params)
  end

  def guest
    @guest ||= build_guest
  end

  def participation
    @participation ||= build_participation
  end

  def additional_emails
    AdditionalEmail.none
  end

  def entry
    first_step? ? guest : participation
  end

  def valid?
    assign_participation_attributes
    super && guest_valid? && participation_valid?
  end

  def save!
    guest.save!
    assign_participation_attributes
    participation.save!
  end

  def required_attrs
    @required_attrs ||= event.required_contact_attrs.map(&:to_sym) +
      event.class.mandatory_contact_attrs
  end

  def policy_finder = Group::PrivacyPolicyFinder.for(group: @group)

  def requires_policy_acceptance? = policy_finder.acceptance_needed?

  private

  def build_guest
    Event::Guest.new(guest_attributes).tap { |guest| guest.main_applicant = guest_of }
  end

  def build_participation
    participation = event.participations.new
    role = participation.roles.build(type: role_type)
    role.participation = participation

    participation
  end

  def role_type
    role_type = guest_of.roles.find { |role| role.class.participant? }
    (role_type || guest_of.roles.first).class
  end

  def guest_attributes
    new_event_guest_contact_data_form.attributes.except("privacy_policy_accepted")
  end

  def assign_participation_attributes
    participation.attributes = new_event_guest_participation_form.attributes
    participation.participant = guest
    participation.enforce_required_answers = true
  end

  def guest_valid?
    return true unless last_step?

    guest.valid?.tap do
      guest.errors.full_messages.each do |msg|
        errors.add(:base, msg)
      end
    end
  end

  def participation_valid?
    return true unless last_step?

    participation.valid?.tap do
      participation.errors.full_messages.each do |msg|
        errors.add(:base, msg)
      end
    end
  end
end
