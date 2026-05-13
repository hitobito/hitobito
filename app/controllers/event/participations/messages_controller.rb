# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club SAC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::Participations::MessagesController < ListController
  self.nesting = [Group, Event, Event::Participation]

  decorates :group, :event, :participation

  private

  def list_entries
    super.page(params[:page]).per(50)
  end

  def participation
    @participation ||= event.participations.find(params[:participation_id])
  end

  def event
    @event ||= group.events.find(params[:event_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_class
    authorize!(:update, participation)
  end
end
