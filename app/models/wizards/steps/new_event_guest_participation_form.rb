# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Wizards::Steps::NewEventGuestParticipationForm < Wizards::Step
  attribute :additional_information, :string

  ### VALIDATIONS
  validates :additional_information,
    length: {allow_nil: true, maximum: (2**16) - 1}
  validate :assert_participation_attrs_valid

  delegate :participation, to: :wizard
  delegate :answers_attributes=, to: :participation

  def self.human_attribute_name(attr, options = {})
    super(attr, default: Event::Participation.human_attribute_name(attr, options))
  end

  def assert_participation_attrs_valid
    unless participation.valid?
      collect_participation_errors
    end
  end

  def collect_participation_errors
    participation.errors.full_messages.each do |m|
      errors.add(:base, m)
    end
  end
end
