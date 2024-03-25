# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Event::Qualifier::StartAtCalculator

  delegate :qualification_date, to: :event, prefix: true

  attr_reader :event

  def initialize(person, event, prolongation_kinds, role)
    @person = person
    @event = event
    @prolongation_kinds = prolongation_kinds
    @role = role
  end

  def start_at(kind)
    start_at = calculator.start_at(kind)
    start_at if start_at && no_qualification_since?(kind, start_at)
  end

  private

  def no_qualification_since?(kind, start_at)
    @person.qualifications
      .where(qualification_kind_id: kind.id).where('start_at >= ?', start_at)
      .none?
  end

  def calculator
    @calculator ||= Event::Qualifier::Calculator.new(
      ([event] + load_courses),
      event_qualification_date
    )
  end

  def load_courses
    Event::TrainingDays::CoursesLoader.new(
      @person.id,
      @role,
      @prolongation_kinds.map(&:id),
      earliest_qualification_date,
      event_qualification_date).load
  end

  def earliest_qualification_date
    event_qualification_date - max_validity
  end

  def max_validity
    @prolongation_kinds.collect(&:validity).compact.max&.years.to_i
  end
end
