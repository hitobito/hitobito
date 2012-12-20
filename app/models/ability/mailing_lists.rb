module Ability::MailingLists
  
  def define_mailing_lists_abilities
    can [:index, :show], MailingList
    
    can [:create, :modify, :index_subscriptions], MailingList do |list|
      can_modify_mailing_list?(list)
    end
    
    can :manage, Subscription do |subscription|
      can_modify_mailing_list?(subscription.mailing_list)
    end
  end
  
  def can_modify_mailing_list?(list)
    group = list.group
    
    # user has group_full for this group
    groups_group_full.include?(group.id) ||
     # user has layer_full, group in same layer
    layers_full.include?(group.layer_group_id)
  end
end