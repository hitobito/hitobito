class PeopleFilterAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Group

  on(::PeopleFilter) do
    permission(:contact_data).may(:new).all
    permission(:group_read).may(:new).in_same_group
    permission(:layer_read).may(:new).in_same_layer_or_below
    permission(:layer_full).may(:create, :destroy).in_same_layer
  end

end