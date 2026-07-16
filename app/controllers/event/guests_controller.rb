# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::GuestsController < Wizards::BaseController
  include PrivacyPolicyAcceptable

  self.wizard_action = :new

  prepend_before_action :authorize_create_or_update_of_main_participation
  before_action :enforce_guest_limit
  before_action :init_answers

  delegate :entry, :guest, :participation, to: :wizard

  helper_method :event
  helper_method :entry
  helper_method :preview_guest_limit

  private

  def model_class
    Wizards::RegisterNewEventGuestWizard
  end

  def wizard
    @wizard ||= model_class.new(
      guest_of: main_participation,
      current_step: params[:step].to_i,
      group:,
      event:,
      current_ability:,
      **model_params.to_unsafe_h
    )
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def event
    @event ||= group.events.find(params[:event_id]).decorate
  end

  def person
    guest.to_person
  end

  def main_participation
    @main_participation ||= event.participations.find(params[:id])
  end

  # We check if a person can either update or create the main participation
  # This is needed because we started using :update in
  # https://github.com/hitobito/hitobito/pull/4264
  #
  # Using update only fixed the issue of not being able to add guests for
  # others but it introduced a bug that if a person registers for an event
  # and wants to add a guest and can't edit their own participation.
  #
  # Currently (July 26) it is only possible to add guests on participations
  # on the creation of a participation (via the UI, it is always possible with the URL)
  # so using :create permission here only would make more sense
  #
  # The issue with :create is that creating participations is not always connected to
  # participation permissions. When creating a participation for someone else it
  # sometimes uses :create permission on a event role, rather than a participation itself.
  #
  # Because the :create permission for participations is not setup the same way,
  # event leaders (or people with an event role with participations_full) do not have
  # the :create permission on a participations but they do on role so they are able
  # to create a participation for others with that.
  #
  # Instead of just giving people with :participations_full the :create permission
  # on participations, we decided to just check any of the two permissions for creating
  # guests for now, until we can rework how the permissions work here.
  #
  # Another reason to not add :create for event roles with :participations_full in core
  # is that some wagons have this as a wagon specific override:
  # https://github.com/hitobito/hitobito_sww/pull/397
  # So granting :create permission to any leader roles is probably not wanted in core
  def authorize_create_or_update_of_main_participation
    action = can?(:update, main_participation) ? :update : :create
    authorize!(action, main_participation)
  end

  def enforce_guest_limit
    if guest_limiter.remaining < 1
      redirect_to group_event_path(group.id, event.id),
        alert: translate(:not_allowed_due_to_guest_limit)
    end
  end

  def preview_guest_limit
    # Subtract the guest who is being added to the event right now
    guest_limiter.preview_remaining(after_adding: 1)
  end

  def init_answers
    @answers = participation.init_answers
  end

  def redirect_target
    if wizard.participation.persisted? && params.key?(:add_another)
      return new_group_event_guest_path(
        params[:group_id],
        params[:event_id],
        params[:id]
      )
    end

    group_event_path(group, event)
  end

  def success_message
    translate(:guest_added_successfully, guest: wizard.guest.to_s)
  end

  private

  def guest_limiter
    @guest_limiter ||= Events::GuestLimiter.for(event, main_participation)
  end
end
