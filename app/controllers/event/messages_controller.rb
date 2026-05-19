# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club SAC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::MessagesController < ListController
  self.nesting = [Group, Event]

  decorates :group, :event

  private

  def list_entries
    super
      .includes(message_recipients: :person)
      .page(params[:page]).per(50)
  end

  def event
    @event ||= group.events.find(params[:event_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_class
    authorize!(:update, event)
  end
end
