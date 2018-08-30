# encoding: utf-8

#  Copyright (c) 2017, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This controller circumvents authorization so OpenShift/Kubernetes can
# inspect the application health without credentials.
# If we'd return 401 the application would be treated as unhealthy.
class HealthzController < ActionController::Base

  protect_from_forgery with: :exception

  def show
    render json: AppStatusSerializer.new(app_status), status: app_status.code
  end

  private

  def app_status
    @app_status ||= AppStatus::Store.new
  end
end
