module RolesHelper
  
  def format_role_created_at(role)
    f(role.created_at.to_date)
  end
  
  def format_role_deleted_at(role)
    f(role.deleted_at.to_date) if role.deleted_at
  end
end