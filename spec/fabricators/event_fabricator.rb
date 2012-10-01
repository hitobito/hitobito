Fabricator(:event) do
  name { 'Eventus' }
end


Fabricator(:course, from: :event, class_name: :'Event::Course') do
end