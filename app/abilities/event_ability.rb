class EventAbility < AbilityDsl::Base

  include AbilityDsl::Conditions::Event

  on(Event) do
    permission(:any).may(:read).all
    permission(:any).may(:update).for_leaded_events
    permission(:any).may(:index_participations).for_event_contacts
    permission(:any).may(:qualify).for_qualify_event
    permission(:group_full).may(:create, :update, :destroy, :index_participations, :application_market, :qualify).in_same_group
    permission(:layer_full).may(:update, :index_participations).in_same_layer_or_below
    permission(:layer_full).may(:create, :destroy, :application_market, :qualify).in_same_layer

    permission(:group_full).may(:manage_courses).if_in_course_group
    permission(:layer_full).may(:manage_courses).if_in_course_layer
  end

  def general_conditions
    case action
    when :create, :destroy, :application_market then at_least_one_group_not_deleted
    else true
    end
  end

  def for_qualify_event
    permission_in_event?(:qualify)
  end

  def if_in_course_group
    in_same_groups(course_offerers)
  end

  def if_in_course_layer
    in_same_layers(course_offerers)
  end

  private

  def event
    subject
  end

  def course_offerers
    @course_offerers ||= Group.course_offerers.pluck(:id)
  end
end