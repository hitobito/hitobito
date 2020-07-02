#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Oauth
  class AuthorizationsController < CrudController
    skip_authorize_resource
    before_action :authorize_class

    def destroy
      unrevoked_access_tokens_and_grants =
        entry.access_tokens.active.where(resource_owner_id: current_user.id) +
        entry.access_grants.active.where(resource_owner_id: current_user.id)
      count = unrevoked_access_tokens_and_grants.map(&:revoke).count
      redirect_to oauth_authorizations_path, notice: t('oauth.authorizations.revoke', count: count)
    end

    def self.model_class
      Oauth::Application
    end

    private

    def entries
      super.joins(:access_grants, :access_tokens)
           .includes(:access_grants, :access_tokens)
           .where(current_user_is_resource_owner)
           .uniq
           .select { |a| a.valid_access_grants.positive? || a.valid_access_grants.positive? }
    end

    def authorize_class
      authorize!(:show, current_user)
    end

    def current_user_is_resource_owner
      [
        'oauth_access_grants.resource_owner_id = ? OR oauth_access_tokens.resource_owner_id = ?',
        current_user.id, current_user.id
      ]
    end
  end
end
