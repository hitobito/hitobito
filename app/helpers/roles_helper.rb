module RolesHelper
  
  def format_role_created_at(role)
    f(role.created_at.to_date)
  end
  
  def format_role_deleted_at(role)
    f(role.deleted_at.to_date) if role.deleted_at
  end
  
  def format_role_group_id(role)
    group = role.group
    # if group was destroyed, we have to get it with #unscoped
    group = Group.unscoped.where(id: role.group_id).first if group.nil?
    # TODO: should we display destroyed groups?
    link_to(group, group) if group
  end
end