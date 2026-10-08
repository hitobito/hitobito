# frozen_string_literal: true

class TagAbility < AbilityDsl::Base
  on(ActsAsTaggableOn::Tag) do
    class_side(:index).if_admin
    permission(:admin).may(:manage).non_validation_tags
  end

  def non_validation_tags
    none_of(name: PersonTags::Validation.tag_names)
  end
end
