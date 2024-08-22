# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# This module is used to extend the roles relation in Person#preload_roles_unscoped /
# #preload_roles to allow preloading the roles association unscoped or with a provided
# scope despite the default scope that is present on Role.
module PreloadRolesUnscoped
  # Preloads the roles association for the given people, either unscoped or with the
  # scope set by an earlier call to #roles_scope.
  def do_preload_roles(entries)
    roles_scope = @roles_scope || Role.with_inactive
    ActiveRecord::Associations::Preloader.new.preload(entries, :roles, roles_scope)
  end

  # This method is called by activerecord to find a single record by id.
  # We override it to preload the roles association.
  def find(...)
    super.tap { |entry| do_preload_roles([entry]) }
  end

  # This method is called by activerecord to execute the query on a relation.
  # We override it to preload the roles association for the people that are returned.
  def exec_queries
    super.tap { |entries| do_preload_roles(entries) }
  end

  def roles_scope(roles_scope)
    @roles_scope = roles_scope
    self
  end
end
