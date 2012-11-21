require Rails.root.join("spec/support/group/bottom_layer.rb")
require Rails.root.join("spec/support/group/top_group.rb")

class Group::TopLayer < Group

  self.default_children = [Group::TopGroup]
  self.layer = true
  self.event_types = [Event, Event::Course]

  children Group::TopGroup, Group::BottomLayer

  roles Role::External
  
end

# no wagons loaded
unless ENV['APP_ROOT']
  Group.reset_types!
  Group.root_types Group::TopLayer
end

