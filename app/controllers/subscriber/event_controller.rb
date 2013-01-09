# encoding: UTF-8
module Subscriber
  class EventController < BaseController

    before_render_form :replace_validation_errors

    # GET query queries available events via ajax
    def query
      events = []
      if params.has_key?(:q) && params[:q].size >= 3
        events = Event.order_by_date.
                 in_year(Time.zone.now.year).
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

    def assign_attributes
      if model_params && model_params[:subscriber_id].present?
        entry.subscriber = Event.find(model_params[:subscriber_id])
      end
    end


    def replace_validation_errors
      if entry.errors[:subscriber_type].present?
        entry.errors.clear
        entry.errors.add(:base, 'Anlass muss ausgewählt werden')
      end

      if entry.errors[:subscriber_id].present?
        entry.errors.clear
        entry.errors.add(:base, 'Anlass wurde bereits hinzugefügt')
      end
    end
  end
end
