# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::LogController < ApplicationController
  before_action :authorize_action

  decorates :group, :event, :versions

  def index
    @group = group
    @versions = PaperTrail::Version
      .changed
      .where(version_conditions)
      .reorder("created_at DESC, id DESC")
      .includes(:item)
      .page(params[:page])
  end

  private

  def version_conditions
    {
      main_id: event.id,
      main_type: Event.sti_name
    }
  end

  def event
    @event ||= Event.find(params[:id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_action
    authorize!(:update, event)
  end
end
