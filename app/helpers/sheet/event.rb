module Sheet
  class Event < Base
    self.parent_sheet = Sheet::Group
    self.has_tabs = true

    def link_url
      view.group_event_path(parent_sheet.entry.id, entry.id)
    end

    def current_parent_nav_path
      view.typed_group_events_path(parent_sheet.entry.id, entry.klass)
    end
  end
end