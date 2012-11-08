class Event::Camp < Event

  attr_accessible :number, :coach_id

  # This statement is required because this class would not be loaded otherwise.
  #load Rails.root.join(*%w(vendor wagons jubla app models event camp role coach.rb))
  load File.join(File.dirname(__FILE__), 'camp', 'role', 'coach.rb')

  include Event::RestrictedRole
  restricted_role :coach, Event::Camp::Role::Coach

end
