module Ability::Qualifications
  
  def define_qualifications_abilities
    
    ### QUALIFICATION KINDS
    if admin
      can :manage, QualificationKind
    end

    can [:create, :destroy], Qualification do |qualification|
      qualify_groups = user.groups_with_permission(:qualify).to_a
      qualify_layers = collect_ids(layers(qualify_groups))
      qualify_layers.present? && 
        contains_any?(qualify_layers, qualification.person.groups_hierarchy_ids)
    end
  end

  
end
