# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::Qualifier
  class << self
    def for(participation)
      person = participation.person
      event = participation.event
      role = qualifier_role(participation)
      new(person, event, role, participation)
    end

    private

    def qualifier_role(participation)
      leader?(participation) ? "leader" : "participant"
    end

    def leader?(participation)
      participation.roles.any? { |role| role.class.leader? }
    end
  end

  attr_reader :created, :prolonged, :participation, :person, :event, :role

  delegate :qualification_date, to: :event

  def initialize(person, event, role, participation = nil)
    @participation = participation
    @person = person
    @event = event

    @created = []
    @prolonged = []
    @role = role
  end

  def issue
    Qualification.transaction do
      issue_qualifications
      participation&.update_column(:qualified, true)
    end
  end

  def revoke
    Qualification.transaction do
      revoke_qualifications
      participation&.update_column(:qualified, false)
    end
  end

  def nothing_changed?
    qualification_kinds.blank? && (prolongation_kinds.present? && prolonged.blank?)
  end

  private

  def issue_qualifications
    @created = QualifyAction.new(person, event, qualification_kinds).run
    @prolonged = ProlongAction.new(person, event, prolongation_kinds, role).run
  end

  def revoke_qualifications
    RevokeAction.new(person, event, qualification_kinds + prolongation_kinds).run
  end

  def qualification_kinds(kind = event.kind)
    kind.qualification_kinds("qualification", @role)
  end

  def prolongation_kinds(kind = event.kind)
    kind.qualification_kinds("prolongation", @role)
  end
end
