# frozen_string_literal: true

#  Copyright (c) 2025-2026, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Oauth
  class AccessTokenCleanupJob < RecurringJob
    run_every 12.hours

    private

    def perform_internal
      delete_non_refreshable_access_tokens
      old_revoked_access_tokens.delete_all
    end

    def old_revoked_access_tokens
      Oauth::AccessToken.where(revoked_at: [..3.days.ago])
    end

    def delete_non_refreshable_access_tokens
      Oauth::Application.find_each do |application|
        application.access_tokens
          .where(created_at: [..application.refresh_token_lifetime.ago.midnight])
          .delete_all
      end
    end
  end
end
