# frozen_string_literal: true

#  Copyright (c) 2021, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::InvitationsController < CrudController
  self.permitted_attrs = [:event_id, :person_id, :participation_type]

  self.nesting = [Group, Event]

  decorates :group, :event

  prepend_before_action :parent, :group

  def create
    super(location: group_event_invitations_path(@group, @event))
  end

  private

  def group
    @group = Group.find(params[:group_id])
  end
  
  def event
    @event = group.events.find(params[:event_id])
  end

  def set_success_notice
    msg = I18n.t('event_invitations.create.flash.success',
                 recipient_name: entry.person.full_name,
                 participation_type: entry.participation_type.constantize.model_name.human)

    flash[:notice] = msg
  end

  def authorize_class
    authorize!(:index_invitations, event)
  end

  class << self
    def model_class
      Event::Invitation
    end
  end
end
