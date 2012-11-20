# == Schema Information
#
# Table name: qualifications
#
#  id                    :integer          not null, primary key
#  person_id             :integer          not null
#  qualification_kind_id :integer          not null
#  start_at              :date             not null
#  finish_at             :date
#  origin                :string(255)
#

Fabricator(:qualification) do
  person
  qualification_kind
  start_at (0..24).to_a.sample.months.ago
end
