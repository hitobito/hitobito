# frozen_string_literal: true

module ActsAsTaggableOnHelper
  # aliasing acts_as_taggable_on_tag to tag path helpers
  def new_acts_as_taggable_on_tag_path
    new_tag_path
  end

  def edit_acts_as_taggable_on_tag_path(entry)
    edit_tag_path(entry)
  end

  def acts_as_taggable_on_tag_path(entry, options = {})
    tag_path(entry, options)
  end

  def acts_as_taggable_on_tags_path(options = {})
    tags_path(options)
  end
end
