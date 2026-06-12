# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::GuestsController < Wizards::BaseController
  include PrivacyPolicyAcceptable

  self.wizard_action = :new

  prepend_before_action :authorize_update_of_main_participation
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

  def authorize_update_of_main_participation
    authorize! :update, main_participation
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
