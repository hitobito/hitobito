# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Handles a top-level event route (/event/:id)
class Event::TopController < ApplicationController

  before_action :authorize_action

  def show
    redirect_to_group_event
  end

  private

  def entry
    @event ||= Event.find(params[:id])
  end

  def redirect_to_group_event
    flash.keep if html_request?
    redirect_to group_event_path(entry.groups.first,
                                 entry,
                                 format: request.format.to_sym,
                                 user_email: params[:user_email],
                                 user_token: params[:user_token])
  end

  def authorize_action
    authorize!(:show, entry)
  end

end
