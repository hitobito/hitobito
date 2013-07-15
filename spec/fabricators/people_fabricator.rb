Fabricator(:person) do
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  nickname { Faker::Name.first_name }
  email { |attrs| "#{attrs[:first_name].downcase.gsub(/[^a-z]/, '')}.#{attrs[:last_name].downcase.gsub(/[^a-z]/, '')}#{sequence}@hitobito.example.com" }
end

Fabricator(:person_with_address, from: :person) do
  address { Faker::Address.street_address }
  town { Faker::Address.city }
  zip_code { Faker::Address.zip_code }
  country { Faker::Address.country }
end

Fabricator(:person_with_address_and_phone, from: :person_with_address) do
  phone_numbers { [Fabricate(:phone_number)] }
end

Fabricator(:company, from: :person) do
  company_name { Faker::Company.name }
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  email { |attrs| "#{attrs[:company_name]}@hitobito.example.com" }
end
