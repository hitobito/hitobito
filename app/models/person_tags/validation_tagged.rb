# frozen_string_literal: true

#  Copyright (c) 2020-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PersonTags::ValidationTagged
  extend ActiveSupport::Concern

  included do
    after_validation :record_validation_run
    after_update :remove_validation_tags, if: :validations_have_been_run?
    after_save :reset_validation_run_cache
  end

  private

  def record_validation_run
    @validations_have_been_run = true
  end

  def validations_have_been_run?
    !!@validations_have_been_run
  end

  def reset_validation_run_cache
    @validations_have_been_run = nil
  end

  # if person can be updated and the validations have been run, all
  # validations passed. so we asume it's safe to remove all validation tags
  # which marks this person for having invalid attributes
  def remove_validation_tags
    tags = PersonTags::Validation.list

    if tags.present?
      ActsAsTaggableOn::Tagging.where(taggable: self, tag: tags).destroy_all
    end
  end
end
