class SubscriptionAbility < AbilityDsl::Base

  include AbilityDsl::Conditions::Group

  on(Subscription) do
    permission(:any).may(:manage).her_own
    permission(:group_full).may(:manage).in_same_group
    permission(:layer_full).may(:manage).in_same_layer
  end

  def her_own
    list = subject.mailing_list
    list.subscribable? && subject.subscriber == user
  end

  def general_conditions
    !group.deleted?
  end

  private

  def group
    subject.mailing_list.group
  end
end