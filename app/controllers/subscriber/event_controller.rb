# encoding: UTF-8
module Subscriber
  class EventController < BaseController

    skip_authorize_resource # must be in leaf class
    
    before_render_form :replace_validation_errors

    # GET query queries available events via ajax
    def query
      events = []
      if params.has_key?(:q) && params[:q].size >= 3
        events = possible_events.joins("LEFT OUTER JOIN event_kinds " +
                                       "ON events.kind_id = event_kinds.id " +
                                       "AND events.type = '#{Event::Course.sti_name}'").
                                 where(search_condition('events.name', 
                                                        'events.number', 
                                                        'groups.name', 
                                                        'event_kinds.label', 
                                                        'event_kinds.short_name')).
                                 order_by_date.
                                 uniq.
                                 limit(10)
        events = decorate(events)
      end

      render json: events.collect(&:as_typeahead)
    end

    private
    
    def subscriber
      possible_events.find(subscriber_id)
    end
    
    def possible_events
      Event.joins(:groups).
            since(start_of_last_year).
            where(groups: { id: @group.sister_groups_with_descendants })
    end
    
    def start_of_last_year
      Time.zone.now.prev_year.beginning_of_year
    end

    def model_label
      Event.model_name.human
    end
  end
end
