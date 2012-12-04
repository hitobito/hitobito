# encoding: utf-8

module RolesHelper
  
  def format_role_created_at(role)
    f(role.created_at.to_date)
  end
  
  def format_role_deleted_at(role)
    f(role.deleted_at.to_date) if role.deleted_at
  end
  
  def format_role_group_id(role)
    if group = role.group
      link_to(group, group)
    else
      group = Group.with_deleted.where(id: role.group_id).first
      group.to_s + " (Gelöscht)"
    end
  end
end