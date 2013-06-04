class Event::Course::ConditionAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Group

  on(Event::Course::Condition) do
    permission(:layer_full).may(:manage).in_same_layer_or_below
  end

end