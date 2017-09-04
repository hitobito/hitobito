# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::QualificationsController < ApplicationController

  before_action :authorize_write, except: :index
  before_action :authorize_read, only: :index

  decorates :event, :leaders, :participants, :group

  helper_method :event

  def index
    entries
  end

  def update
    Qualification.transaction do
      entries
      (@leaders + @participants).uniq.each do |participation|
        qualifier = Event::Qualifier.for(participation)
        qualified = Array(params[:participation_ids]).include?(participation.id.to_s)
        qualified ? qualifier.issue : qualifier.revoke
      end
    end

    redirect_to group_event_qualifications_path(group, event),
                notice: t('event.qualifications.update.flash.success')
  end

  private

  def entries
    types = event.role_types
    @leaders ||= participations(*types.select(&:leader?))
    @participants ||= participations(*types.select(&:participant?))
  end

  def event
    @event ||= group.events.find(params[:event_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def participations(*role_types)
    event.participations_for(*role_types).includes(:roles, :event)
  end

  def authorize_write
    event_qualifying
    authorize!(:qualify, event)
  end

  def authorize_read
    event_qualifying
    authorize!(:qualifications_read, event)
  end

  def event_qualifying
    not_found unless event.course_kind? && event.qualifying?
  end

end
