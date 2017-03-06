# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::PersonAddRequestsController < ApplicationController

  before_action :authorize_action

  prepend_before_action :group

  decorates :add_requests

  # list add requests for the given layer
  def index
    @add_requests = load_entries
    load_approvers if group.require_person_add_requests
    set_status_notification if show_status_notification?
  end

  def activate
    group.update_column(:require_person_add_requests, true)
    redirect_to group_person_add_requests_path, notice: translate(:activated)
  end

  def deactivate
    group.update_column(:require_person_add_requests, false)
    Person::AddRequest::IgnoredApprover.where(group_id: group.id).destroy_all
    redirect_to group_person_add_requests_path, notice: translate(:deactivated)
  end

  private

  def load_entries
    Person::AddRequest.
      for_layer(group).
      includes(:person,
               requester: { roles: :group }).
      merge(Person.order_by_name)
  end

  def load_approvers
    @possible_approvers = Person::AddRequest::IgnoredApprover.
                            possible_approvers(group).
                            includes(roles: :group).
                            order_by_name
    @ignored_approvers = Person::AddRequest::IgnoredApprover.
                            where(group_id: group.id).
                            pluck(:person_id)
  end

  def show_status_notification?
    flash[:notice].blank? && flash[:alert].blank? &&
      params[:person_id].present? && params[:body_type].present? && params[:body_id].present?
  end

  def set_status_notification
    status = request_status
    return if status.nil? || !person_in_layer?(status)

    if status.pending?
      @current_add_request = status.pending
    elsif status.created?
      flash.now[:notice] = status.approved_message
    else
      flash.now[:alert] = status.rejected_message
    end
  end

  def request_status
    Person::AddRequest::Status.for(
      params[:person_id], params[:body_type], params[:body_id])
  end

  def person_in_layer?(status)
    status.person.primary_group.try(:layer_group_id) == group.layer_group_id
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_action
    authorize!(:"#{action_name}_person_add_requests", group)
  end

end
