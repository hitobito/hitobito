# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Person::Address
  def initialize(person)
    @person = person
  end

  def for_letter
    ([@person.full_name.to_s.squish] + address).compact.join("\n")
  end

  def for_household_letter(names)
    (names + address).compact.join("\n")
  end

  private

  def address
    [@person.address.to_s.squish,
     [@person.zip_code, @person.town].compact.join(' ').squish,
     country]
  end

  def country
    country = @person.country.to_s.squish
    return if country.eql?(default_country)

    country
  end

  def default_country
    Settings.countries.prioritized.first
  end
end
