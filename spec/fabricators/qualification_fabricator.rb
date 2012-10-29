Fabricator(:qualification) do
  person
  qualification_kind
  start_at (0..36).to_a.sample.months.ago
end
