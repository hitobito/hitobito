# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Event::Qualifier::ProlongAction < Event::Qualifier::QualifyAction
  def initialize(person, event, kinds, role)
    super(person, event, kinds)

    @role = role
  end

  def run
    prolongation_kinds.collect do |kind|
      next create(kind) if kind.required_training_days.blank?

      start_at = calculator.start_at(kind)
      create(kind, start_at: start_at) if start_at
    end.compact
  end

  private

  def calculator
    @calculator ||= Event::Qualifier::StartAtCalculator.new(
      @person,
      @event,
      prolongation_kinds,
      @role
    )
  end

  def prolongation_kinds
    @prolongation_kinds ||= @person
      .qualifications
      .includes(:qualification_kind)
      .where(qualification_kind_id: @kinds.map(&:id))
      .select { |quali| quali.reactivateable?(event_start_date) }
      .map(&:qualification_kind)
  end

  def event_start_date
    @event.start_date
  end
end
