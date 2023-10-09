# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::Destroyer

  def initialize(person)
    @person = person
  end

  def run
    family_members_to_cleanup = leftover_family_members

    @person.destroy

    family_members_to_cleanup.destroy_all
  end

  def leftover_family_members
    FamilyMember.where(family_key: @person.family_members.pluck(:family_key))
                .having('COUNT(*) <= 1')
                .group(:family_key)
  end

end
