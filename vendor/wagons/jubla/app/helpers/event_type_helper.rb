module EventTypeHelper

  def supports_courses?(group)
    group.kind_of?(Group::State) || group.kind_of?(Group::Federation)
  end

  def supports_camps?(group)
    group.kind_of?(Group::Flock)
  end

  def new_specific_event_button
    event = @group.events.new
    event.groups << @group
    if can?(:new, event)
      event_type = (params[:type] && params[:type].constantize) || Event

      if @group.possible_events.include?(event_type)
        action_button("#{event_type.model_name.human} erstellen" ,
                      new_group_event_path(@group, event: { type: event_type.sti_name}),
                      :plus)
      end
    end
  end

end
