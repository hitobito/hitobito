# frozen_string_literal: true

class TagAbility < AbilityDsl::Base

  on(ActsAsTaggableOn::Tag) do
    class_side(:index).if_admin
    permission(:admin).may(:manage).non_validation_tags
  end

  def non_validation_tags
    PersonTags::Validation.tag_names.exclude?(subject.name)
  end

end
