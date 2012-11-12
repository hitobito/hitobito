
Fabricator(:group) do
  name { Faker::Name.name }
end

Group.all_types.collect {|g| g.name.to_sym }.each do |t|
  Fabricator(t, from: :group, class_name: t)
end
