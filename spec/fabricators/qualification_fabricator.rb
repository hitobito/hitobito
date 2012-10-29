Fabricator(:qualification) do
  person
  qualification_kind
  start_at { ((Date.today - 2.years)..Date.today).to_a.sample }
end
