# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:invoice) do
  title { Faker::Name.name }
end

Fabricator(:invoice_article) do
  number    { Faker::Number.hexadecimal(5).to_s.upcase }
  name      { Faker::Commerce.product_name }
  unit_cost { Faker::Commerce.price }
end

Fabricator(:payment_reminder) do
  title    { Faker::Lorem.words }
  text     { Faker::Lorem.words }
  level    { 1 }
end
