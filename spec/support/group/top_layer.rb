require Rails.root.join("spec/support/group/top_group.rb")
require Rails.root.join("spec/support/group/bottom_layer.rb")

class Group::TopLayer < Group

  self.default_children = [Group::TopGroup]
  self.layer = true
  self.event_types = [Event, Event::Course]

  children Group::TopGroup, Group::BottomLayer
  
end

