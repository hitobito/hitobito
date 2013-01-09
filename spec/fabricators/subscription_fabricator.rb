Fabricator(:subscription) do
  subscriber { Fabricate(:person) }
end
