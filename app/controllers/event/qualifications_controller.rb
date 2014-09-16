# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::QualificationsController < ApplicationController

  before_action :authorize

  decorates :event, :leaders, :participants, :participation, :group

  helper_method :event, :participation

  def index
    entries
  end

  def update
    qualifier.issue

    @nothing_changed = qualifier.nothing_changed?

    respond_to do |format|
      format.html { redirect_to group_event_qualifications_path(group, event) }
      format.js   { render 'qualification' }
    end
  end

  def destroy
    qualifier.revoke

    respond_to do |format|
      format.html { redirect_to group_event_qualifications_path(group, event) }
      format.js   { render 'qualification' }
    end
  end

  private

  def entries
    types = event.class.role_types
    @leaders ||= participations(*types.select(&:leader?))
    @participants ||= participations(*types.select(&:participant?))
  end

  def qualifier
    @qualifier ||= Event::Qualifier.for(participation)
  end

  def event
    @event ||= group.events.find(params[:event_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def participation
    @participation ||= event.participations.find(params[:id])
  end

  def participations(*role_types)
    event.participations_for(*role_types).includes(:roles, :event)
  end

  def authorize
    not_found unless event.course_kind? && event.qualifying?
    authorize!(:qualify, event)
  end
end
