#  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class DashboardController < ApplicationController
  CUSTOM_DASHBOARD_PAGE_CONTENT = "custom_dashboard_page_content"

  skip_before_action :authenticate_person!, only: :index
  skip_authorization_check only: [:index, :dashboard]

  respond_to :json

  def index
    authenticate_person! unless html_request?

    flash.keep

    redirect_to target_path(current_user, request.format.to_sym)
  end

  def dashboard
    return redirect_to root_path unless FeatureGate.enabled? "custom_dashboard_page"

    content = CustomContent.get(CUSTOM_DASHBOARD_PAGE_CONTENT)
    @subject = content.subject_with_values
    @body = content.body_with_values
  end

  private

  def target_path(current_user, format)
    if current_user.nil?
      new_person_session_path
    elsif format == :html && FeatureGate.enabled?("custom_dashboard_page")
      dashboard_path
    else
      person_home_path(current_user, format: format)
    end
  end
end
