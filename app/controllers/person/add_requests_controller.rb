# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestsController < ApplicationController

  authorize_resource except: [:index, :activate, :deactivate]

  before_action :authorize_class, only: [:index, :activate, :deactivate]

  prepend_before_action :group, only: [:index, :activate, :deactivate]
  prepend_before_action :entry, only: [:approve, :reject]

  # list add requests for the given layer
  def index
    @add_requests = load_entries
    set_status_notification
  end

  def activate
    group.update_column(:require_person_add_requests, true)
    redirect_to group_person_add_requests_path, notice: translate(:activated)
  end

  def deactivate
    group.update_column(:require_person_add_requests, false)
    redirect_to group_person_add_requests_path, notice: translate(:deactivated)
  end

  def approve
    approver = Person::AddRequest::Approver.for(entry, current_user)
    if approver.approve
      redirect_back notice: t('person.add_requests.approve.success_notice',
                              person: entry.person.full_name)
    else
      redirect_back alert: t('person.add_requests.approve.failure_notice',
                             person: entry.person.full_name,
                             errors: approver.error_message)
    end
  end

  def reject
    Person::AddRequest::Approver.for(entry, current_user).reject
    action = params[:cancel] ? 'cancel' : 'reject'
    redirect_back notice: t("person.add_requests.#{action}.success_notice",
                            person: entry.person.full_name)
  end

  private

  def entry
    @entry ||= Person::AddRequest.find(params[:id])
  end

  def load_entries
    Person::AddRequest.
      for_layer(group).
      includes(:body,
               person: :primary_group,
               requester: { roles: :group }).
      merge(Person.order_by_name)
  end

  def set_status_notification
    status = request_status
    return if status.nil? || !person_in_layer?(status)

    if status.pending?
      @current = status.pending # TODO: highlight in list
    elsif status.created?
      flash.now[:notice] = status.approved_message
    else
      flash.now[:alert] = status.rejected_message
    end
  end

  def request_status
    return if params[:person_id].blank? || params[:body_type].blank? || params[:body_id].blank?

    Person::AddRequest::Status.for(
      params[:person_id], params[:body_type], params[:body_id])
  end

  def person_in_layer?(status)
    status.person.primary_group.try(:layer_group_id) == group.layer_group_id
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def redirect_back(options = {})
    if request.env['HTTP_REFERER'].present?
      redirect_to :back, options
    else
      redirect_to person_path(entry.person), options
    end
  end

  def authorize_class
    authorize!(:"#{action_name}_person_add_requests", group)
  end

end
