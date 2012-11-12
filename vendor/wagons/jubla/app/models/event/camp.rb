class Event::Camp < Event

  attr_accessible :number, :coach_id

  # This statement is required because this class would not be loaded otherwise.
  require_dependency 'event/camp/role/coach'

  include Event::RestrictedRole
  restricted_role :coach, Event::Camp::Role::Coach

end
