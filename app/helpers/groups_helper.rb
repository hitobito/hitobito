# encoding: utf-8
module GroupsHelper
  
  def new_event_button
    event = @group.events.new
    event.groups << @group
    if can?(:new, event)
      Dropdown::EventAdd.new(self, @group)
    end
  end

end
