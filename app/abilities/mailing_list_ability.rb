class MailingListAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Group

  on(::MailingList) do
    permission(:any).may(:index, :show).all
    permission(:group_full).may(:index_subscriptions, :create, :update, :destroy).in_same_group
    permission(:layer_full).may(:index_subscriptions, :create, :update, :destroy).in_same_layer

    general.group_not_deleted
  end

end