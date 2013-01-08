# no wagons loaded
unless ENV['APP_ROOT']
  Group.reset_types!
  
  # global roles and children
  load Rails.root.join("spec/support/group/external_role.rb")
  Group.roles Role::External

  load Rails.root.join("spec/support/group/global_group.rb")
  Group.children Group::GlobalGroup
    
  load Rails.root.join("spec/support/group/top_layer.rb")
  Group.root_types Group::TopLayer
end

