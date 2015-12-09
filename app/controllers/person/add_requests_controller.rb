# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestsController < ApplicationController

  authorize_resource except: :index

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
    redirect_to group_person_add_requests_path notice: 'TODO activated'
  end

  def deactivate
    group.update_column(:require_person_add_requests, false)
    redirect_to group_person_add_requests_path notice: 'TODO deactivated'
  end

  def approve
    if Person::AddRequest::Approver.for(entry).approve
      # redirect back with notice
    else
      # redirect back with error
    end
  end

  def reject
    Person::AddRequest::Approver.for(entry).reject
    # redirect back with notice
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
    return if params[:person_id].blank? || params[:body_type].blank? || params[:body_id].blank?

    status = Person::AddRequest::Status.for(
      group, params[:person_id], params[:body_type], params[:body_id])
    return unless status.person_in_layer? # prevent information leaking

    if status.pending?
      @current = status.pending # TODO: highlight in list
    elsif status.created?
      flash.now[:notice] = status.approved_message
    else
      flash.now[:error] = status.rejected_message
    end
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_class
    authorize!(:"#{action_name}_person_add_requests", group)
  end

end
