# encoding: utf-8
module GroupsHelper

  def new_event_button
    event = @group.events.new
    event.groups << @group
    if can?(:new, event)
      event_type = (params[:type] && params[:type].constantize) || Event

      if @group.event_types.include?(event_type)
        action_button("#{event_type.model_name.human} erstellen" ,
                      new_group_event_path(@group, event: { type: event_type.sti_name}),
                      :plus)
      end
    end
  end

end
