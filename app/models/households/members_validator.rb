# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Households::MembersValidator < ActiveModel::Validator

  delegate :people, :members, to: :'@household'

  def validate(household)
    @household = household
    minimum_members
    household_addresses
  end

  private

  def household_address
    Households::Address.new(@household)
  end

  def minimum_members
    if members.size < 2
      @household.warnings.add(:members, :minimum_members)
    end
  end

  def household_addresses
    if household_address.dirty?
      @household.warnings.add(:members, :household_address, address: household_address.oneline)
    end
  end
  
end
