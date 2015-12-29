# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::PersonAddRequestIgnoredApproversController < ApplicationController

  before_action :authorize_action

  def update
    if params[:set_approver]
      ignored_approver.destroy!
    else
      ignored_approver.save!
    end
    head :ok
  end

  private

  def ignored_approver
    Person::AddRequest::IgnoredApprover.
      where(group_id: params[:group_id], person_id: params[:person_id]).
      first_or_initialize
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_action
    authorize!(:activate_person_add_requests, group)
  end

end
