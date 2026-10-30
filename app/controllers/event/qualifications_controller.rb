#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::QualificationsController < ApplicationController
  before_action :authorize_write, except: :index
  before_action :authorize_read, only: :index

  decorates :event, :group

  helper_method :event

  def index
    entries
  end

  def update
    submitted = assign_submitted_qualifications

    if submitted.map(&:valid?).all?
      Qualification.transaction do
        submitted.each(&:apply)
      end

      redirect_to group_event_qualifications_path(group, event),
        notice: t("event.qualifications.update.flash.success")
    else
      entries
      render :index, status: :unprocessable_content
    end
  end

  private

  def qualifiers
    @qualifiers ||= qualifyable_participations.map do |participation|
      Event::Qualifier.for(participation)
    end
  end

  def qualifyable_participations
    event
      .participations_for(*Event::Qualifier.qualifyable_role_types(event))
      .includes(:roles, :event)
      .order_by_name
  end

  def entries
    @leaders, @participants =
      qualifiers
        .partition { |q| q.role_kind == "leader" }
        .map { |list| list.map(&:participation).map(&:decorate) }
  end

  def assign_submitted_qualifications
    qualifiers.filter do |qualifier|
      attrs = permitted_params(qualifier.participation.id)
      qualifier.participation.assign_attributes(attrs) if attrs
      !attrs.nil?
    end
  end

  def permitted_params(participation_id)
    if FeatureGate.enabled?("event.qualifications.comments")
      params.dig(:qualifications, participation_id.to_s)
        &.permit(:qualified, :qualification_comment)
    else
      {qualified: Array(params[:participation_ids]).include?(participation_id.to_s)}
    end
  end

  def event
    @event ||= group.events.find(params[:event_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
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
