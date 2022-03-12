# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CalendarTag < ActiveRecord::Base
  belongs_to :calendar
  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag'

  scope :excluded, -> { where(excluded: true) }
  scope :included, -> { where(excluded: false) }
end
