#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Oauth
  class ActiveAuthorizationsController < ApplicationController
    helper_method :entries

    def index
      authorize!(:show, current_user)
      entries
    end

    def destroy
      authorize!(:show, current_user)
      application = entries.find(params[:id])

      revoke!(application.access_grants)
      revoke!(application.access_tokens)

      message = t("oauth.authorizations.revoke", application: application)
      redirect_to oauth_active_authorizations_path, notice: message
    end

    private

    # rubocop:disable Rails/SkipsModelValidations
    def revoke!(scope)
      scope.where(resource_owner_id: current_user.id).update_all(revoked_at: Time.zone.now)
    end
    # rubocop:enable Rails/SkipsModelValidations

    def entries
      @entries ||= current_user.oauth_applications.list
    end
  end
end
