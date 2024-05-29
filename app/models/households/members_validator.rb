# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Households::MembersValidator < ActiveModel::Validator

  def validate(household)
    @household = household
    minimum_members
  end

  private

  def minimum_members
    if @household.members.size < 2
      @household.warnings.add(:members, :minimum_members)
    end
  end

end
