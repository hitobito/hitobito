class SimpleAbility < AbilityDsl::Base

  on(CustomContent) do
    permission(:admin).may(:index, :update).all
  end

  on(Event::Kind) do
    permission(:admin).may(:manage).all
  end

  on(LabelFormat) do
    permission(:admin).may(:manage).all
  end

  on(QualificationKind) do
    permission(:admin).may(:manage).all
  end

end