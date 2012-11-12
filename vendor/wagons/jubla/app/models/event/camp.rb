class Event::Camp < Event

  attr_accessible :number, :coach_id, :kind_id

  # This statement is required because this class would not be loaded otherwise.
  require_dependency 'event/camp/role/coach'
  require_dependency 'event/camp/kind'

  include Event::RestrictedRole
  restricted_role :coach, Event::Camp::Role::Coach

  belongs_to :kind, class_name: 'Event::Camp::Kind'

end
