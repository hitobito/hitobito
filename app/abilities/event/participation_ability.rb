class Event::ParticipationAbility < AbilityDsl::Base

  include AbilityDsl::Conditions::Event
  include AbilityDsl::Conditions::Event::Participation

  on(::Event::Participation) do
    permission(:any).may(:show).her_own_or_for_event_contacts
    permission(:any).may(:show_details, :print).her_own_or_for_leaded_events
    permission(:layers_full).may(:show, :show_details, :print, :update).in_same_layer_or_below
    permission(:group_full).may(:show, :show_details, :print, :create, :update, :destroy).in_same_group
    permission(:approve_applications).may(:show).for_applicant_in_same_layer

    permission(:any).may(:create).her_own_if_application_possible
    permission(:layers_full).may(:create, :destroy).in_same_layer

    permission(:any).may(:update).for_leaded_events
  end

  def general_conditions
    case action
    when :create then at_least_one_group_not_deleted
    else
      true
    end
  end

  def her_own_or_for_leaded_events
    her_own || for_leaded_events
  end

  def her_own_or_for_event_contacts
    her_own_or_for_leaded_events || for_event_contacts
  end

  def her_own_if_application_possible
    her_own && event.application_possible?
  end


  private

  def participation
    subject
  end
end