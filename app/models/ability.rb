class Ability
  include Ability::Common
  
  include Ability::People
  include Ability::Groups
  include Ability::Events
  include Ability::Various
  
  def initialize(user)
    super(user)
    
    if user.root?
      can :manage, :all
    elsif user.login?
      define_abilities
    else
      # generall, a user without login permission cannot do anything
      can [:show, :modify], Person do |person|
        person.id == user.id
      end
    end
  end
  
  def define_abilities
    define_people_abilities
    define_groups_abilities
    define_events_abilities
    define_various_abilities
  end

end
