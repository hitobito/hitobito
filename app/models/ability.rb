class Ability
  include Ability::Common
  
  include Ability::People
  include Ability::Groups
  include Ability::Events
  include Ability::MailingLists
  include Ability::Various
  
  def initialize(user)
    super(user)
    
    if user.root?
      can :manage, :all
    else
      define_abilities
    end
  end
  
  def define_abilities
    define_people_abilities
    define_groups_abilities
    define_events_abilities
    define_mailing_lists_abilities
    define_various_abilities
  end

end
