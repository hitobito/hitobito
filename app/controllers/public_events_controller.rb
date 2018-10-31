# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PublicEventsController < ApplicationController
  skip_authorization_check
  skip_before_action :authenticate_person!
  before_action :assert_public_access, :assert_external_application_possible

  helper_method :entry

  decorates :entry

  private

  def assert_external_application_possible
    session[:person_return_to] = event_url
    redirect_to new_person_session_path unless entry.external_applications
  end

  def assert_public_access
    redirect_to event_url if current_user
  end

  def event_url
    group_event_path(group, entry)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def entry
    @entry ||= group.events.find(params[:id])
  end
end
