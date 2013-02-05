module Dropdown
  class EventAdd < Base
    
    attr_reader :group
    
    def initialize(template, group)
      super(template, 'Anlass erstellen', :plus)
      @group = group
      init_items
    end
    
    def to_s
      if items.size == 1
        item = items.first
        template.action_button("#{item.label} erstellen", item.link, icon)
      else
        super
      end
    end
    
    private
        
    def init_items
      group.possible_events.each do |type|
        item(type.label, event_link(type))
      end
    end

    def event_link(et)
      template.new_group_event_path(group, event: {type: et.sti_name})
    end

  end
end