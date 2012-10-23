# == Schema Information
#
# Table name: events
#
#  id                     :integer          not null, primary key
#  group_id               :integer          not null
#  type                   :string(255)
#  name                   :string(255)      not null
#  number                 :string(255)
#  motto                  :string(255)
#  cost                   :string(255)
#  maximum_participants   :integer
#  contact_id             :integer
#  description            :text
#  location               :text
#  application_opening_at :date
#  application_closing_at :date
#  application_conditions :text
#  kind_id                :integer
#  state                  :string(60)
#  priorization           :boolean          default(FALSE), not null
#  requires_approval      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  participant_count      :integer          default(0)
#

Fabricator(:event) do
  name { 'Eventus' }
  group { Group.all_types.first.first }
end


Fabricator(:course, from: :event, class_name: :'Event::Course') do
  group { Group.all_types.detect {|t| t.event_types.include?(Event::Course) }.first }
  kind { Fabricate(:event_kind) }
  priorization { true }
  requires_approval { true }
end
