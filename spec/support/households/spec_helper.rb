# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Households::SpecHelper
  extend ActiveSupport::Concern

  def create_household(reference_person, *others)
    household = Household.new(reference_person)
    others.each { |person| household.add(person) }
    household.save!
  end
end
