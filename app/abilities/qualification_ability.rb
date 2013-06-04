class QualificationAbility < AbilityDsl::Base

  on(Qualification) do
    permission(:qualify).may(:create, :destroy).in_same_layer_or_below
  end

  def in_same_layer_or_below
    qualify_layer_ids = user_context.layer_ids(user.groups_with_permission(:qualify))
    qualify_layer_ids.present? &&
    contains_any?(qualify_layer_ids, subject.person.groups_hierarchy_ids)
  end

end