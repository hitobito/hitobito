# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::Qualifier

  class << self
    def for(participation)
      new(participation, qualifier_role(participation))
    end

    private

    def qualifier_role(participation)
      leader?(participation) ? 'leader' : 'participant'
    end

    def leader?(participation)
      participation.roles.any? { |role| role.class.leader? }
    end
  end

  attr_reader :created, :prolonged, :participation, :role

  delegate :person, :event, to: :participation
  delegate :qualification_date, to: :event

  def initialize(participation, role)
    @participation = participation

    @created = []
    @prolonged = []
    @role = role
  end

  def issue
    issue_qualifications
    participation.update_column(:qualified, true)
  end

  def revoke
    revoke_qualifications
    participation.update_column(:qualified, false)
  end

  def nothing_changed?
    qualification_kinds.blank? && (prolongation_kinds.present? && prolonged.blank?)
  end

  private

  def issue_qualifications
    Qualification.transaction do
      create_qualifications
      prolong_existing(prolongation_kinds)
    end
  end

  def revoke_qualifications
    Qualification.transaction do
      remove(qualification_kinds + prolongation_kinds)
    end
  end

  def create_qualifications
    @created = qualification_kinds.map { |kind| create(kind) }
  end

  # Creates new qualification for prolongable qualifications,
  # tracks what could and could not be prolonged
  def prolong_existing(kinds)
    @prolonged = prolongable_qualification_kinds(kinds)
    @prolonged.each do |kind|
      next create(kind) if kind.required_training_days.blank?

      start_at = calculator.start_at(kind)
      create(kind, start_at: start_at) if start_at
    end
  end

  def calculator
    @calculator ||= StartAtCalculator.new(@participation, prolongation_kinds, @role)
  end

  def create(kind, start_at: qualification_date)
    person.qualifications
      .where(qualification_kind_id: kind.id)
      .where(qualified_at: qualification_date)
      .first_or_create!(origin: event.to_s, start_at: start_at)
  end

  def prolongable_qualification_kinds(kinds)
    person.qualifications
      .includes(:qualification_kind)
      .where(qualification_kind_id: kinds.map(&:id))
      .select { |quali| quali.reactivateable?(event.start_date) }
      .map(&:qualification_kind)
  end

  def remove(kinds)
    obtained(kinds).each(&:destroy)
  end

  # Qualifications set for this qualification_date (via preceeding #issue call in controller)
  def obtained(kinds = [], qualified_at = qualification_date)
    @obtained ||= person.qualifications.where(qualified_at: qualified_at,
                                              qualification_kind_id: kinds.map(&:id)).to_a
  end

  def qualification_kinds
    event.kind.qualification_kinds('qualification', @role)
  end

  def prolongation_kinds
    event.kind.qualification_kinds('prolongation', @role)
  end
end
