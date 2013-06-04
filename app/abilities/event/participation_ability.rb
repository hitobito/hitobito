class Event::ParticipationAbility < AbilityDsl::Base

  include AbilityDsl::Constraints::Event
  include AbilityDsl::Constraints::Event::Participation

  on(Event::Participation) do
    permission(:any).may(:show).her_own_or_for_event_contacts
    permission(:any).may(:show_details, :print).her_own_or_for_leaded_events
    permission(:any).may(:create).her_own_if_application_possible
    permission(:any).may(:update).for_leaded_events

    permission(:group_full).may(:show, :show_details, :print, :create, :update, :destroy).in_same_group

    permission(:layer_full).may(:show, :show_details, :print, :update).in_same_layer_or_below
    permission(:layer_full).may(:create, :destroy).in_same_layer

    permission(:approve_applications).may(:show).for_applicant_in_same_layer

    general(:create).at_least_one_group_not_deleted
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