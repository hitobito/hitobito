module Ability::Qualifications
  
  def define_qualifications_abilities
    
    ### QUALIFICATION KINDS
    if admin
      can :manage, QualificationKind
    end
  end
  
end