# == Schema Information
#
# Table name: qualification_types
#
#  id          :integer          not null, primary key
#  label       :string(255)      not null
#  validity    :integer
#  description :string(1023)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#

Fabricator(:qualification_type) do
  label { Faker::Company.bs }
  validity { 2 }
end
