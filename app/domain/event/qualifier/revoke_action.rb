# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Event::Qualifier::RevokeAction < Event::Qualifier::QualifyAction

  def initialize(person, event, qualification_kinds)
    @person = person
    @qualification_date = event.qualification_date
    @qualification_kinds = qualification_kinds
  end

  def run
    obtained.each(&:destroy)
  end

  private

  # Qualifications set for this qualification_date (via preceeding #issue call in controller)
  def obtained
    @person.qualifications.where(
      qualified_at: @qualification_date,
      qualification_kind_id: @qualification_kinds.map(&:id)
    )
  end

end
