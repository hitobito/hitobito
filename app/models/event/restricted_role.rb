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
    participations.joins(:roles).where(event_roles: {type: type.sti_name})
  end

end
