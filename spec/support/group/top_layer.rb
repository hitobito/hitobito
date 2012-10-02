require Rails.root.join("spec/support/group/top_group.rb")
require Rails.root.join("spec/support/group/bottom_layer.rb")

class Group::TopLayer < Group

  self.default_children = [Group::TopGroup]
  self.layer = true
  self.event_types = [Event, Event::Course]

  children Group::TopGroup, Group::BottomLayer
  
  class External < ::Role
    self.visible_from_above = false
    self.affiliate = true
  end
  
  roles External
  
end

# no wagons loaded
unless ENV['APP_ROOT']
  Group.reset_types!
  Group.root_types Group::TopLayer
end

