# frozen_string_literal :true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require Rails.root.join('spec/support/group/top_group.rb')
require Rails.root.join('spec/support/group/bottom_layer.rb')

class Group::TopLayer < Group

  self.default_children = [Group::TopGroup]
  self.layer = true
  self.event_types = [Event, Event::Course]

  children Group::TopGroup, Group::BottomLayer

  class TopAdmin < ::Role
    self.permissions = [:group_and_below_full]
  end

  roles TopAdmin

  mounted_attr :foundation_year, :integer, default: 1942
  mounted_attr :custom_name, :string, category: :custom_cat
  mounted_attr :shirt_size, :string, enum: %w(s l xl)

  validates :foundation_year, numericality: { greater_than: 1850 }, allow_nil: true

end
