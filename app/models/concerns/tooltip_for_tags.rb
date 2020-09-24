# frozen_string_literal: true

module TooltipForTags

  extend ActiveSupport::Concern

  # We cannot decorate ActsAsTaggableOn::Tag, so we have to add the attribute this way
  attr_accessor :hitobito_tooltip

end
