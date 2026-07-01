# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

Fabricator(:address) do
  street_short { Faker::Address.street_name }
  street_long { Faker::Address.street_name }
  street_short_old { Faker::Address.street_name }
  street_long_old { Faker::Address.street_name }
  zip_code { Faker::Address.zip_code }
  town { Faker::Address.city }
  state { Faker::Address.state_abbr }
  numbers { [] }
end
