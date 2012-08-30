Fabricator(:role) do
  person
end

Role.all_types.each do |r|
  Fabricator(r.name.to_sym, from: :role, class_name: r.name.to_sym)
end
