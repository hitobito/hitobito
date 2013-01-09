# encoding: UTF-8
module Subscriber
  class EventController < BaseController

    before_render_form :replace_validation_errors

    # GET query queries available events via ajax
    def query
      events = []
      if params.has_key?(:q) && params[:q].size >= 3
        events = Event.order_by_date.
                 since(start_of_last_year).
                 joins(:groups).
                 joins("LEFT OUTER JOIN event_kinds on events.kind_id = event_kinds.id AND events.type = '#{Event::Course.sti_name}'").
                 where(groups: { id: @group.sister_groups_with_descendants }).
                 where(search_condition('events.name', 'events.number', 'groups.name', 'event_kinds.label')).
                 uniq.
                 limit(10)
        events = decorate(events)
      end

      render json: events.collect(&:as_typeahead)
    end

    private

    def start_of_last_year
      Time.zone.now.prev_year.beginning_of_year
    end

    def assign_attributes
      if model_params && model_params[:subscriber_id].present?
        entry.subscriber = Event.find(model_params[:subscriber_id])
      end
    end

    def model_label
      Event.model_name.human
    end
  end
end
