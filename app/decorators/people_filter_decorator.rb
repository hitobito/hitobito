class PeopleFilterDecorator < BaseDecorator
    
  def searchable_group_types
    group.layer_group.class.child_types.
      collect {|group_type| [group_type, local_role_types(group_type) ]}.
      select {|group_type, role_types| role_types.present? }
  end
  
  def local_role_types(group)
    group.role_types.select {|r| r.name.start_with?(group.name) }
  end
  
  def global_role_types
    Role.all_types.reject {|r| r.name.start_with?('Group::') }
  end
  
end