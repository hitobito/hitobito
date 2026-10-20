# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

class Bulk::TagBulkJob < BaseJob
  prepend ObservableJob

  BATCH_SIZE = 500

  self.parameters = [:ids, :tag_names, :job_observation_id]
  self.reports_progress = true

  def initialize(ids, tag_names)
    @ids = ids
    @tag_names = tag_names
    super()
  end

  def perform
    batch_count = (@ids.size / BATCH_SIZE.to_f).ceil
    @ids.each_slice(BATCH_SIZE).with_index do |batch, index|
      perform_action(tag_list(batch))
      report_progress!(index + 1, batch_count)
    end
  end

  private

  def perform_action(tag_list)
    raise NotImplementedError
  end

  def tag_list(ids)
    TagList.new(people(ids), tags)
  end

  def people(ids)
    Person.where(id: ids).includes(:tags).distinct
  end

  def tags
    @tags ||= ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(@tag_names)
  end
end
