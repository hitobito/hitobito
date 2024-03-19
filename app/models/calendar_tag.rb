# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: calendar_tags
#
#  id          :bigint           not null, primary key
#  excluded    :boolean          default(FALSE)
#  calendar_id :bigint           not null
#  tag_id      :integer          not null
#
# Indexes
#
#  fk_rails_b4e7ba0100                 (tag_id)
#  index_calendar_tags_on_calendar_id  (calendar_id)
#
# Foreign Keys
#
#  fk_rails_...  (tag_id => tags.id) ON DELETE => cascade
#

class CalendarTag < ActiveRecord::Base
  belongs_to :calendar
  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag'

  scope :excluded, -> { where(excluded: true) }
  scope :included, -> { where(excluded: false) }
end
