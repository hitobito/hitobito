# frozen_string_literal: true

#  Copyright (c) 2021, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::Invitations::DeclineController < ApplicationController

  before_action :authorize_action

  def create
    Event::Invitation.transaction do
      entry.declined_at = Time.zone.now

      entry.save!

      withdraw_applications
    end

    redirect_to group_event_path(@group, @event), notice: declined_message
  end

  private

  def declined_message
    I18n.t('event_invitations.decline.flash.success')
  end

  def withdraw_applications
    entry.related_participation&.application&.toggle_approval(false)
  end

  def entry
    @entry ||= event.invitations.find(params[:id])
  end
  
  def event
    @event ||= group.events.find(params[:event_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_action
    authorize!(:decline, entry)
  end
end
