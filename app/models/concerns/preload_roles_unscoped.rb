# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module PreloadRolesUnscoped
  def _preload_roles(people)
    roles_scope = @roles_scope || Role.with_inactive
    ActiveRecord::Associations::Preloader.new.preload(people, :roles, roles_scope)
  end

  def find(...)
    super.tap { |person| _preload_roles([person]) }
  end

  def exec_queries
    super.tap { |people| _preload_roles(people) }
  end

  def roles_scope(roles_scope)
    @roles_scope = roles_scope
    self
  end
end
