# == Schema Information
#
# Table name: event_kinds
#
#  id          :integer          not null, primary key
#  label       :string(255)      not null
#  short_name  :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#  minimum_age :integer
#

Fabricator(:event_kind, class_name: 'Event::Kind') do
  label { Faker::Company.bs }
end
