# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Participations::LogController < ApplicationController
  before_action :authorize_action

  decorates :group, :event, :participation, :versions

  def index
    @group = group
    @event = event
    @versions = PaperTrail::Version
      .changed
      .where(version_conditions)
      .reorder("created_at DESC, id DESC")
      .includes(item: [:translations, {question: :translations}])
      .page(params[:page])
  end

  private

  def version_conditions
    {
      main_id: participation.id,
      main_type: Event::Participation.sti_name
    }
  end

  def participation = @participation ||= event.participations.find(params[:id])

  def event = @event ||= group.events.find(params[:event_id])

  def group = @group ||= Group.find(params[:group_id])

  def authorize_action = authorize!(:update, participation)
end
