# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class GroupReadables < GroupBasedReadables

  def initialize(user)
    super(user)

    can :index, Group, accessible_groups
  end

  private

  def accessible_groups
    return Group.all if user.root? || user.roles.any?

    Group.none
  end
end
