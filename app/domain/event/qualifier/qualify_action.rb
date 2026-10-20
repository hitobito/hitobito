# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Event::Qualifier::QualifyAction
  def initialize(person, event, role_kind)
    @person = person
    @event = event
    @role_kind = role_kind
  end

  def run
    @event.kind.qualification_kinds("qualification", @role_kind).map do |kind|
      create(kind)
    end
  end

  private

  def create(kind, start_at: qualification_date)
    qualifications(kind).first_or_create!(origin: origin, start_at: start_at)
  end

  def qualifications(kind)
    @person
      .qualifications
      .where(qualification_kind_id: kind.id, qualified_at: qualification_date)
  end

  def qualification_date
    @event.qualification_date
  end

  def origin
    @event.to_s
  end
end
