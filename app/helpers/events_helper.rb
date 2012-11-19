module EventsHelper
  
  def event_group_sheet
    parent_sheet(GroupSheet.new(self, @group, :group_events_path, :index_events))
  end
end