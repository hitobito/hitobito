# frozen_string_literal: true

module PersonTags::ValidationTagged

  extend ActiveSupport::Concern

  included do
    after_update :remove_validation_tags
  end

  private

  # if person can be updated, all validations passed. so we asume it's save to remove
  # all validation tags which marks this person for having invalid attributes
  def remove_validation_tags
    tags = PersonTags::Validation.list
    if tags.present?
      ActsAsTaggableOn::Tagging.where(taggable: self, tag: tags).destroy_all
    end
  end
end
