# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  type             :string(255)      not null
#  participation_id :integer          not null
#  label            :string(255)
#


Fabricator(:event_role, class_name: 'Event::Role') do
  participation { Fabricate(:event_participation) }
end

types = Event.role_types + [Event::Course::Role::Participant]
types.collect {|t| t.name.to_sym }.each do |t|
  Fabricator(t, from: :event_role, class_name: t)
end
