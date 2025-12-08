# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module TooltipForTags
  extend ActiveSupport::Concern

  # We cannot decorate ActsAsTaggableOn::Tag, so we have to add the attribute this way
  attr_accessor :hitobito_tooltip
end
