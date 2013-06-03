class Event::RoleAbility < AbilityDsl::Base
  include AbilityDsl::Conditions::Event

  on(::Event::Role) do
    permission(:any).may(:manage).for_leaded_events
    permission(:group_full).may(:manage).in_same_group
    permission(:layer_full).may(:manage).in_same_layer_or_below
  end

  private

  def event
    subject.participation.event
  end
end