# == Schema Information
#
# Table name: event_applications
#
#  id            :integer          not null, primary key
#  priority_1_id :integer          not null
#  priority_2_id :integer
#  priority_3_id :integer
#  approved      :boolean          default(FALSE), not null
#  rejected      :boolean          default(FALSE), not null
#  waiting_list  :boolean          default(FALSE), not null
#

Fabricator(:event_application, class_name: 'Event::Application') do
  priority_1    { Fabricate(:course) }
  priority_2    { Fabricate(:course) }
end
