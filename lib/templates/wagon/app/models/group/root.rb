# frozen_string_literal: true

# TODO: rename class to specific name and change all references
class Group::Root < ::Group
  self.layer = true

  # TODO: define actual child group types
  children Group::Root

  ### ROLES

  # TODO: define actual role types
  class Leader < ::Role
    self.permissions = [:layer_and_below_full, :admin]
  end

  class Member < ::Role
    self.permissions = [:group_read]
  end

  roles Leader, Member
end
