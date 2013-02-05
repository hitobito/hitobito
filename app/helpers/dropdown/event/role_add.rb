# encoding: utf-8
module Dropdown
  module Event
    class RoleAdd < Dropdown::Base
        
      attr_reader :group, :event
      
      def initialize(template, group, event)
        super(template, 'Person hinzufügen', :plus)
        @group = group
        @event = event
        init_items
      end
      
      private
      
      def init_items
        event.klass.role_types.each do |type|
          unless type.restricted
            link = template.new_group_event_role_path(group, event, event_role: { type: type.sti_name })
            item(type.label, link)
          end
        end
      end
    end
  end
end
