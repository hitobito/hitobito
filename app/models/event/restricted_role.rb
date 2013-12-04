# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Usage: restricted_role :advisor, Role::Advisor
# Adds an accessors for a restricted role to the current group.
# So it is possible to change the assigned Person like a regular group attribute.
module Event::RestrictedRole
  extend ActiveSupport::Concern

  include ::RestrictedRole

  private

  def build_restricted_role(role, id)
    role.participation = participations.where(person_id: id).first_or_create
    role
  end

  def restricted_role_scope(type)
    participations.joins(:roles).where(event_roles: { type: type.sti_name })
  end

end
