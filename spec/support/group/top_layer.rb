# encoding: utf-8

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

end
