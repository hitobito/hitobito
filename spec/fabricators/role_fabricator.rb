# == Schema Information
#
# Table name: roles
#
#  id                 :integer          not null, primary key
#  person_id          :integer          not null
#  group_id           :integer          not null
#  type               :string(255)      not null
#  label              :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  deleted_at         :datetime
#  employment_percent :integer
#  honorary           :boolean
#

Fabricator(:role) do
  person
end

Role.all_types.collect {|r| r.name.to_sym }.each do |t|
  Fabricator(t, from: :role, class_name: t)
end
