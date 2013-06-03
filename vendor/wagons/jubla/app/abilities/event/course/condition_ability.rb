class Event::Course::ConditionAbility < AbilityDsl::Base

  include AbilityDsl::Conditions::Group

  on(Event::Course::Condition) do
    permission(:layer_full).may(:manage).in_same_layer_or_below
  end

end