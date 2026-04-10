Fabricator(:pass_definition) do
  owner { Group.root }
  name { Faker::Lorem.unique.words(number: 3).join(" ") }
  template_key { "default" }
  background_color { "#0066cc" }
end
