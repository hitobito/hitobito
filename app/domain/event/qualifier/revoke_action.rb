# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Event::Qualifier::RevokeAction
  def initialize(person, event, role_kind)
    @person = person
    @event = event
    @role_kind = role_kind
  end

  def run
    obtained.each(&:destroy)
  end

  private

  # Qualifications set for this qualification_date (via preceeding #issue call in controller)
  def obtained
    @person.qualifications.where(
      qualified_at: @event.qualification_date,
      qualification_kind_id: qualification_kinds.map(&:id)
    )
  end

  def qualification_kinds
    @event.kind.qualification_kinds(%w[qualification prolongation], @role_kind)
  end
end
