# frozen_string_literal: true

#  Copyright (c) 2022-2025,  Eidgenössischer Jodlerverband. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:additional_address) do
  contactable { Fabricate(:person) }
  street { Faker::Address.street_name }
  housenumber { Faker::Address.building_number }
  zip_code { Faker::Address.zip_code }
  town { Faker::Address.city }
  country { Faker::Address.country_code }
  label { AdditionalAddress.predefined_labels.first }
end
