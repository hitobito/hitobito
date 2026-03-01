Fabricator(:pass_membership) do
  person { Fabricate(:person) }
  pass_definition
  state { :eligible }
  valid_from { Time.zone.today }
end
