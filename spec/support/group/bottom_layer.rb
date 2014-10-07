# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require Rails.root.join('spec/support/group/bottom_group.rb')

class Group::BottomLayer < Group

  self.layer = true

  self.event_types = [Event, Event::Course]

  children Group::BottomGroup


  class Leader < ::Role
    self.permissions = [:layer_and_below_full, :contact_data, :approve_applications]
  end

  class LocalGuide < ::Role
    self.permissions = [:layer_full]
  end

  class Member < ::Role
    self.permissions = [:layer_and_below_read]
  end

  roles Leader, LocalGuide, Member

end
