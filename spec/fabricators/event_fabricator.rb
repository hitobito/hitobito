Fabricator(:event) do
  name { 'Eventus' }
  group
end


Fabricator(:course, from: :event, class_name: :'Event::Course') do
  group { Group.all_types.detect {|t| t.event_types.include?(Event::Course) }.first }
end