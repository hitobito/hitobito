# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Creates a person without an account who signs up for an event with external applications.
# Wagons add data for such people in after_create callbacks, e.g. a role in the event's group.
class Event::Registration::PersonCreator
  extend ActiveModel::Callbacks

  define_model_callbacks :create

  attr_reader :event, :group

  delegate :person, to: :contact_data

  def initialize(event:, group:, contact_data:, privacy_policy_accepted:)
    @event = event
    @group = group
    @contact_data = contact_data
    @privacy_policy_accepted = privacy_policy_accepted
  end

  def save
    return false unless contact_data.valid? && privacy_policy_accepted?

    person.privacy_policy_accepted = true if privacy_policy_finder.acceptance_needed?
    Person.transaction { run_callbacks(:create) { contact_data.save } }
  end

  private

  attr_reader :contact_data

  def privacy_policy_accepted?
    privacy_policy_finder.accepted?(@privacy_policy_accepted)
  end

  def privacy_policy_finder
    @privacy_policy_finder ||= Group::PrivacyPolicyFinder.for(group: group, person: person)
  end
end
