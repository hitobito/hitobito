Fabricator(:person) do
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  nickname { Faker::Name.first_name }
  email { |attrs| "#{attrs[:first_name]}.#{attrs[:last_name]}@jubla.example.com" }
end

Fabricator(:company, from: :person) do
  company_name { Faker::Company.name }
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  email { |attrs| "#{attrs[:company_name]}@jubla.example.com" }
end
