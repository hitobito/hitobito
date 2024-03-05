module Types
  include Dry.Types()

  EventDateType = Types::Strict::Hash.schema(
    location: Types::Strict::String.optional,
    start_at: Graphiti::Types::ReadDateTime,
    finish_at: Graphiti::Types::ReadDateTime,
    label: Types::Strict::String.optional
  ).constructor(&:attributes).with_key_transform(&:to_sym)

  Graphiti::Types[:array_of_event_dates] = {
    canonical_name: name,
    params: Types::Strict::Array.of(Graphiti::Types::PresentParamsHash),
    read: Types::Coercible::Array.of(EventDateType),  # converting from AR relation
    kind: 'array',
    write: nil,
    test: nil,
    description: 'List of Event Dates.'
  }
end
