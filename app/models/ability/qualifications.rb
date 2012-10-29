module Ability::Qualifications
  
  def define_qualifications_abilities
    
    ### QUALIFICATION KINDS
    if admin
      can :manage, QualificationKind
    end

    can :qualify, Person do |person|
      true
      #contains_any?(layers_full, collect_ids(person.layer_groups))
    end
  end

  
end
