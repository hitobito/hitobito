# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:message_recipient) do
  message { Fabricate(:letter) }
  person { Fabricate(:person) }

  state { :pending }

  address { Faker::Address.street_address }
  email do
    first = Faker::Name.first_name
    last = Faker::Name.last_name
    "#{first}.#{last}#{sequence}@hitobito.example.com"
  end
  phone_number { Fabricate(:phone_number) }
end
