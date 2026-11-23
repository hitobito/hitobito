# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# Replaces a role by a role of another type or in another group, both in one
# transaction. Returns whether the old role was removed and the new one saved.
class Roles::TypeChange
  attr_reader :old_role, :new_role

  def initialize(old_role, new_role)
    @old_role = old_role
    @new_role = new_role
  end

  def call
    Role.transaction do
      (old_role.destroy && new_role.save) || raise(ActiveRecord::Rollback)
    end
  end
end
