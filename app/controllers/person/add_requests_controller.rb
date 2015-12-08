# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestsController < ApplicationController

  authorize_resource except: :index

  before_action :authorize_class, only: :index

  prepend_before_action :parent, only: :index
  prepend_before_action :entry, only: [:show, :new, :create, :edit, :update, :destroy]

  # list add requests for the given layer
  def index
    @add_requests = load_entries
    set_status_notification
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

  alias_method :group, :parent

  def entry
    @entry ||= Person::AddRequest.find(params[:id])
  end

  def load_entries
    Person::AddRequest.
      joins(person: :primary_group).
      where(groups: { layer_group_id: group.id }).
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

  def authorize_class
    authorize!(:index_person_add_requests, group)
  end

end
