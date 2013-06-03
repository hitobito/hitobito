class MailingListAbility < AbilityDsl::Base

  include AbilityDsl::Conditions::Group

  on(::MailingList) do
    permission(:any).may(:index, :show).all
    permission(:group_full).may(:create, :modify, :index_subscriptions).in_same_group
    permission(:layer_full).may(:create, :modify, :index_subscriptions).in_same_layer
  end

  def general_conditions
    !group.deleted?
  end
end