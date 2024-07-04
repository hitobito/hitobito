# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:person) do
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  nickname { Faker::Name.first_name }
  email do |attrs|
    first = attrs[:first_name]&.downcase&.gsub(/[^a-z]/, "")
    last = attrs[:last_name]&.downcase&.gsub(/[^a-z]/, "")
    "#{first}.#{last}#{sequence}@hitobito.example.com"
  end
  confirmed_at { 1.hour.ago }
end

Fabricator(:person_with_address, from: :person) do
  address_care_of { Faker::Address.secondary_address if (1..10).to_a.shuffle == 1 }
  street { Faker::Address.street_name }
  housenumber { Faker::Address.building_number }
  postbox { Faker::Address.mail_box if (1..10).to_a.shuffle == 1 }
  town { Faker::Address.city }
  zip_code { Faker::Address.zip_code[0..3] }
  country { Faker::Address.country_code }
end

Fabricator(:person_with_address_and_phone, from: :person_with_address) do
  phone_numbers { [Fabricate(:phone_number)] }
end

Fabricator(:person_with_phone, from: :person) do
  phone_numbers { [Fabricate(:phone_number, label: "Mobil")] }
end

Fabricator(:company, from: :person) do
  company_name { Faker::Company.name }
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  email { |attrs| "#{attrs[:company_name]}@hitobito.example.com" }
end
