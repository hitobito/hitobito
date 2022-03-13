# encoding: utf-8

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Tags
  extend ActiveSupport::Concern

  included do
    before_render_show :load_grouped_tags, if: -> { html_request? }
  end

  private

  def load_grouped_tags
    @tags = collect_grouped_tags
  end

  def collect_grouped_tags
    tags = entry.taggings.includes(:tag).order('tags.name').each_with_object({}) do |t, memo|
      tag = t.tag
      tag.hitobito_tooltip = t.hitobito_tooltip

      memo[tag.category] ||= []
      memo[tag.category] << tag
    end
    ActsAsTaggableOn::Tag.order_categorized(tags)
  end
end
