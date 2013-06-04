class Event::ApplicationAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Event
  include AbilityDsl::Constraints::Event::Participation

  on(Event::Application) do
    permission(:any).may(:show).her_own
    permission(:group_full).may(:show).in_same_group
    permission(:layer_full).may(:show).in_same_layer
    permission(:approve_applications).may(:show, :approve, :reject).for_applicant_in_same_layer
  end

end