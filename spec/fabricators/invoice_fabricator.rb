#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:invoice) do
  title { Faker::Name.name }
  recipient_name { Faker::Name.name }
  recipient_street { Faker::Address.street_address }
  recipient_zip_code { Faker::Address.zip_code[0..3] }
  recipient_town { Faker::Address.city }
  recipient_country { Faker::Address.country }
end

Fabricator(:invoice_article) do
  number { Faker::Number.hexadecimal(digits: 5).to_s.upcase }
  name { Faker::Commerce.product_name }
  unit_cost { (Faker::Commerce.price / 0.05).to_i * BigDecimal("0.05") }
end

Fabricator(:payment_reminder) do
  title { Faker::Lorem.sentence }
  text { Faker::Lorem.sentence(word_count: 5) }
  level { 1 }
end
