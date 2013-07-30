# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::TopGroup < Group

  self.event_types = [Event, Event::Course]

  class Leader < ::Role
    self.permissions = [:admin, :layer_full, :contact_data]
  end

  class Secretary < ::Role
    self.permissions = [:layer_read, :contact_data, :group_full]
  end

  class Member < ::Role
    self.permissions = [:contact_data, :group_read]
  end

  roles Leader, Secretary, Member

end
