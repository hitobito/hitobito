# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# See doc/developer/event/qualifications.md for details.
class Event::Qualifier
  class << self
    def for(participation)
      new(participation, qualifier_role(participation))
    end

    def qualifyable_role_types(event)
      event.role_types.select { |type| type.leader? || type.qualifiable? || type.participant? }
    end

    private

    def qualifier_role(participation)
      leader?(participation) ? "leader" : "participant"
    end

    def leader?(participation)
      participation.roles.any? { |role| role.class.leader? || role.class.qualifiable? }
    end
  end

  attr_reader :participation, :role_kind

  delegate :person, :event, to: :participation
  delegate :qualification_date, to: :event

  def initialize(participation, role_kind)
    @participation = participation
    @role_kind = role_kind
  end

  def apply
    Qualification.transaction do
      if participation.qualified
        issue
      else
        revoke
      end
      participation.save!
    end
  end

  def issue
    QualifyAction.new(person, event, role_kind).run
    ProlongAction.new(person, event, role_kind).run
  end

  def revoke
    RevokeAction.new(person, event, role_kind).run
  end

  def valid?
    participation.valid?(:qualification)
  end
end
