# no wagons loaded
unless ENV['APP_ROOT']
  Group.reset_types!
  
  # global roles and children
  require Rails.root.join("spec/support/group/external_role.rb")
  Group.roles Role::External

  require Rails.root.join("spec/support/group/global_group.rb")
  Group.children Group::GlobalGroup
    
  require Rails.root.join("spec/support/group/top_layer.rb")
  Group.root_types Group::TopLayer
end

