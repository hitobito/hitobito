#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::TopGroup < Group
  self.event_types = [Event, Event::Course]

  children Group::TopGroup

  class Leader < ::Role
    self.permissions = [:admin, :finance, :layer_and_below_full, :contact_data, :impersonation]
  end

  class LocalGuide < ::Role
    self.permissions = [:layer_full]
  end

  class Secretary < ::Role
    self.permissions = [:layer_and_below_read, :contact_data, :group_full]
  end

  class LocalSecretary < ::Role
    self.permissions = [:layer_read]
  end

  class GroupManager < ::Role
    self.permissions = [:group_and_below_full]
  end

  class Member < ::Role
    self.permissions = [:contact_data, :group_and_below_read]
  end

  class InvisiblePeopleManager < ::Role
    self.permissions = [:see_invisible_from_above]
  end

  roles Leader, LocalGuide, Secretary, LocalSecretary, GroupManager, Member, InvisiblePeopleManager
end
