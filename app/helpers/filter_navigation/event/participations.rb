module FilterNavigation
  module Event
    class Participations < FilterNavigation::Base
      
      PREDEFINED_FILTERS = { all: 'Alle Personen',
                             teamers: 'Leitungsteam',
                             participants: 'Teilnehmende' }.with_indifferent_access
               
      attr_reader :group, :event, :filter
      
      delegate :can?, to: :template
      
      def initialize(template, group, event, filter)
        super(template)
        @group = group
        @event = event
        @filter = filter
        init_labels
        init_items
        init_dropdown_items
      end
      
      private
    
      def init_labels
        if role_labels.include?(filter)
          dropdown.label = filter
          dropdown.active = true
        elsif PREDEFINED_FILTERS.has_key?(filter)
          @active_label = PREDEFINED_FILTERS[filter]
        elsif filter.blank?
          @active_label = PREDEFINED_FILTERS.values.first
        end
      end
      
      def init_items
        PREDEFINED_FILTERS.each do |key, value|
          item(value, event_participation_filter_link(key))
        end
      end
      
      def init_dropdown_items
        role_labels.each do |label|
          dropdown.item(label, event_participation_filter_link(label))
        end
      end
        
      def role_labels
        @role_labels ||= event.participation_role_labels
      end
      
      def event_participation_filter_link(filter)
        template.group_event_participations_path(group, event, filter: filter)
      end
    end
  end
end