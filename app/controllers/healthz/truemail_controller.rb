# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
require_dependency 'app_status/truemail'

class Healthz::TruemailController < HealthzController

  before_action :validate_token

  private

  def app_status
    @app_status ||= AppStatus::Truemail.new
  end

  def validate_token
    unless AppStatus.auth_token == params[:token]
      render json: '', status: :unauthorized
    end
  end

end
