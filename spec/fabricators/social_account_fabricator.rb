Fabricator(:social_account) do
  contactable { Fabricate(:person) }
  name { Faker::Internet.user_name }
end
