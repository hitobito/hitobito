class Event::ParticipationResource < ApplicationResource
  self.type = :event_participations

  belongs_to :event, resource: EventResource
  belongs_to :person, resource: PersonResource

  attribute :event_id, :integer
  attribute :role_types, :array_of_strings do
    @object.roles.map(&:type)
  end

  filter :role_type, :string do
    eq do |scope, value|
      scope.joins(:roles).where(event_roles: {type: value})
    end
  end

  def base_scope
    Event::Participation.includes(:roles)
  end
end
