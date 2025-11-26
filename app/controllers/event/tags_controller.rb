# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::TagsController < TaggableController
  before_action :load_group, :load_event

  decorates :group, :event

  private

  def entry
    @event
  end

  def entry_path
    group_event_path(@group, @event)
  end

  def load_group
    @group = Group.find(params[:group_id])
  end

  def load_event
    @event = Event.find(params[:event_id])
  end
end
