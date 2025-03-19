# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

class Bulk::TagAddJob < BaseJob
  self.parameters = [:ids, :tag_names]

  def initialize(ids, tag_names)
    @ids = ids
    @tag_names = tag_names
    super
  end

  def perform
    TagList.new(people, tags).add
  end

  private

  def people
    Person.where(id: @ids).includes(:tags).distinct
  end

  def tags
    ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(@tag_names)
  end
end
