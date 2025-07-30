# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::GuestsController < Wizards::BaseController
  include PrivacyPolicyAcceptable

  self.wizard_action = :new

  authorize_resource :guest, class: Event::Guest

  prepend_before_action :guest_of
  before_action :enforce_guest_limit
  before_action :init_answers

  delegate :entry, :guest, :participation, to: :wizard

  helper_method :event
  helper_method :entry

  private

  def model_class
    Wizards::RegisterNewEventGuestWizard
  end

  def wizard
    @wizard ||= model_class.new(
      group: group,
      event: event,
      guest_of: guest_of,
      current_step: params[:step].to_i,
      current_ability: current_ability,
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

  def guest_of
    @guest_of ||= event.participations.find_by!(
      participant: current_person,
      id: params[:id]
    )
  end

  def enforce_guest_limit
    if Events::GuestLimiter.for(event, guest_of).remaining < 1
      redirect_to group_event_path(group.id, event.id),
        alert: translate(:not_allowed_due_to_guest_limit)
    end
  end

  def init_answers
    @answers = participation.init_answers
  end

  def redirect_target
    group_event_path(group, event)
    # TODO add capability for add_another to the step wizards and set the redirect_target according
    #   to whether the add_another param was submitted
  end

  def success_message
    translate(:guest_added_successfully, guest: wizard.guest.to_s)
  end
end
